#include "library.h"

#include <string>
#include <Windows.h>
#include <iostream>
#include <mutex>

#include "RichTextLabel.hpp"
#include "TextHistory"

#pragma clang diagnostic ignored "-Wswitch"

using namespace godot;

HANDLE hJob;
HANDLE hInputRead, hInputWrite, hOutputRead, hOutputWrite;
PROCESS_INFORMATION pi;
bool shouldTerminate = false;

std::string history;
std::vector<int> history_linebreaks;
std::mutex buffer_mutex;
int history_lines = 0;
int history_last_fetched_pos = 0;

std::mutex termination_mutex;

/////////////

const int tab32[32] = {
        0,  9,  1, 10, 13, 21,  2, 29,
        11, 14, 16, 18, 22, 25,  3, 30,
        8, 12, 20, 28, 15, 17, 24,  7,
        19, 27, 23,  6, 26,  5,  4, 31};
int log2_32(uint32_t value)
{
    value |= value >> 1;
    value |= value >> 2;
    value |= value >> 4;
    value |= value >> 8;
    value |= value >> 16;
    return tab32[(uint32_t)(value*0x07C4ACDD) >> 27];
}

/////////////

// console/stdio history lines
String to_str(int n) {
    return {std::to_string(n).c_str()};
}
String to_str(float n) {
    return {std::to_string(n).c_str()};
}
void simpleDebugPrint(const char *str) {
    std::cout << str << std::endl;
}
void PrintErr(const char *err) {
    std::cerr << err << std::endl;
    ERR_PRINT(err);
}
void printOutput(const char *buffer, DWORD bytesRead) {
    // Convert CRLF to LF
    std::string formatted = buffer;
    std::string::size_type pos = 0;
    while ((pos = formatted.find("\r\n", pos)) != std::string::npos)
        formatted.replace(pos, 1, "");

    // Further process string
    // TODO

    // Flush to local std::cout as well
    std::cout << formatted.c_str();
    std::cout.flush();

    // Extract and record linebreaks
    int string_start = history.size(); //NOLINT
    std::lock_guard<std::mutex> guard(buffer_mutex);
    if (history_linebreaks.empty())
        history_linebreaks.push_back(0); // always have '0' as the first one
    pos = 0;
    while ((pos = formatted.find('\n', pos)) != std::string::npos) {
        pos += 1; // record the START of each line!
        history_linebreaks.push_back(string_start + pos); //NOLINT
    }
    history_lines = history_linebreaks.size(); //NOLINT

    // Push string into history
    history += formatted;
}
bool redirectStdout() {
    while (true) {
        DWORD dwAvail = 0;
        if (!PeekNamedPipe(hOutputRead, nullptr, 0, nullptr, &dwAvail, nullptr))
            break; // error, the child process might have ended

        if (!dwAvail) // no data available, return
            return false;

        char buffer[4096];
        DWORD bytesRead = 0;

        if (!ReadFile(hOutputRead, buffer, sizeof(buffer), &bytesRead, nullptr) || bytesRead == 0)
            break; // error, the child process might have ended

        buffer[bytesRead] = 0;
        printOutput(buffer, bytesRead); // display the output (push to internal history)
    }
    return true;
}
void clear_history() {
    std::lock_guard<std::mutex> guard(buffer_mutex);
    history.clear();
    history_linebreaks.clear();
    history_last_fetched_pos = 0;
    history_lines = 0;
}
int GDNShell::get_lines_count() {
    return history_lines;
}
String GDNShell::get_text(int start_line, int end_line) {
    std::lock_guard<std::mutex> guard(buffer_mutex);
    const int last_line = history_linebreaks.size(); //NOLINT

    if (history.size() == 0) //NOLINT
        return "";

    // if negative, scroll to the bottom
    if (start_line < 0) {
        start_line += last_line;
        end_line += last_line;
    }

    int s_start;
    if (start_line >= last_line)
        return "";
    else {
        start_line = Math::clamp(start_line, 0, last_line - 1);
        s_start = history_linebreaks.at(start_line);
    }

    int s_end;
    if (end_line >= last_line)
        s_end = history.size(); //NOLINT
    else {
        end_line = Math::clamp(end_line, 0, last_line - 1);
        s_end = history_linebreaks.at(end_line);
    }

    s_start = Math::clamp(s_start, 0, int(history.size() - 1));
    s_end = Math::clamp(s_end, 0, int(history.size() - 1));

    if (start_line != end_line && s_start != s_end)
        return history.substr(s_start, s_end - s_start).c_str();
    return "";
}
String GDNShell::get_all_text() {
    std::lock_guard<std::mutex> guard(buffer_mutex);
    const int history_size = history.size(); //NOLINT
    if (history_size != history_last_fetched_pos) {
        int n = history_size - history_last_fetched_pos;
        std::string str = history.substr(history_last_fetched_pos, n);
        auto buf = str.c_str();
        history_last_fetched_pos = history_size;
        return buf;
    }
    return "";
}
void GDNShell::clear() {
    clear_history();
}

// child process spawn/kill/management
int GDNShell::spawn(String path, bool hidden) {
    simpleDebugPrint("--> GDNShell::spawn CALL");
    simpleDebugPrint("GDNShell::spawn 1");

    // Clear previous history and buffers
    clear_history();

    STARTUPINFO si = { sizeof(STARTUPINFO) };

    if (hidden) {
        // Create pipes for input and output
        SECURITY_ATTRIBUTES sa = { sizeof(SECURITY_ATTRIBUTES), nullptr, TRUE };
        if (!CreatePipe(&hOutputRead, &hOutputWrite, &sa, 0) ||
            !CreatePipe(&hInputRead, &hInputWrite, &sa, 0))
        {
            PrintErr("Failed to create pipes.");
            return (int)GetLastError();
        }
        simpleDebugPrint("GDNShell::spawn 2");
        si.dwFlags |= STARTF_USESTDHANDLES;
        si.hStdOutput = hOutputWrite;
        si.hStdError = hOutputWrite;
        si.hStdInput = hInputRead;

        // Set the window style to hide the child process window
        si.dwFlags |= STARTF_USESHOWWINDOW;
        si.wShowWindow = SW_HIDE;
    }

    // Create the child process
    if (!CreateProcess(nullptr, path.alloc_c_string(), nullptr, nullptr, TRUE, CREATE_SUSPENDED, nullptr, nullptr, &si, &pi))
    {
        PrintErr("Failed to create process.");
        return (int)GetLastError();
    }
    simpleDebugPrint("GDNShell::spawn 3");

    // Associate the child process with the job object
    if (!AssignProcessToJobObject(hJob, pi.hProcess))
    {
        PrintErr("Failed to assign child process to job object.");
        CloseHandle(pi.hProcess);
        CloseHandle(pi.hThread);
        return (int)GetLastError();
    }
    simpleDebugPrint("GDNShell::spawn 4");

    // Resume the child process
    ResumeThread(pi.hThread);

    // Close unnecessary pipe handles
    CloseHandle(hOutputWrite);
    CloseHandle(hInputRead);
    simpleDebugPrint("GDNShell::spawn 5");

    // Clear previous terminal history and raise signal
    emit_signal("child_process_started");
    simpleDebugPrint("GDNShell::spawn 6");

    // Main loop
    char buffer[4096];
    DWORD bytesRead;
    simpleDebugPrint("----> GDNShell::spawn LOOP ENTER");
    while (true) {
        // Lock thread until termination is done
        std::lock_guard<std::mutex> guard(termination_mutex);

        // Message queue
        bool r = redirectStdout();

        // Check if the child process has exited
        DWORD childStatus;
        if (GetExitCodeProcess(pi.hProcess, &childStatus) && childStatus != STILL_ACTIVE)
            break;

        // Exit the loop manually
        if (shouldTerminate) {
            simpleDebugPrint("shouldTerminate is TRUE");
            break;
        }
    }
    simpleDebugPrint("<---- GDNShell::spawn LOOP EXIT");

    if (shouldTerminate) {
        // Manual termination requested, terminate the child process
        DWORD childStatus;
        if (GetExitCodeProcess(pi.hProcess, &childStatus) && childStatus != STILL_ACTIVE)
            simpleDebugPrint("GetExitCodeProcess gave NOT STILL_ACTIVE");
        else
            simpleDebugPrint("GetExitCodeProcess gave STILL_ACTIVE");
        TerminateProcess(pi.hProcess, 0);
        shouldTerminate = false;
    } else {
        // Wait for the child process to exit
        WaitForSingleObject(pi.hProcess, INFINITE);
    }
    simpleDebugPrint("GDNShell::spawn 8");

    // Cleanup
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
    emit_signal("child_process_stopped");
    simpleDebugPrint("<-- GDNShell::spawn RET");
    return 0;
}
bool GDNShell::send_string(String string) {
    char *s = string.alloc_c_string();
    DWORD bytesWritten;
    if (!WriteFile(hInputWrite, s, static_cast<DWORD>(strlen(s)), &bytesWritten, nullptr))
    {
        PrintErr("Failed to write to child process.");
        return false;
    }

    printOutput(s, strlen(s));
    return true;
}
void GDNShell::kill() {
    simpleDebugPrint("--> GDNShell::kill CALL");
    // Request process termination
    std::lock_guard<std::mutex> guard(termination_mutex);
    shouldTerminate = true;
    simpleDebugPrint("<-- GDNShell::kill RET");
}

// disassembler
#include "distorm.h"
#include "mnemonics.h"
#define MAX_INSTRUCTIONS 3200
Array GDNShell::disassemble(PoolByteArray bytes, int bitformat, unsigned int address) {
    // convert PoolByteArray into a raw byte (char) array that stupid piece of garbage C can parse >:(
    uint8_t *bytes_s;
    bytes_s = (uint8_t*)bytes.read().ptr();

    // decompile!
    _DecodedInst decoded[MAX_INSTRUCTIONS];
    unsigned int num_instr = 0;
    _DecodeResult r = distorm_decode(address,
                                     bytes_s,
                                     bytes.size(),
                                     (_DecodeType)bitformat,
                                     decoded,
                                     MAX_INSTRUCTIONS,
                                     &num_instr);

    // fit results into a Godot array of dictionaries
    Array a;
    if (r == DECRES_INPUTERR)
        return a;
    _DecodedInst *cur = nullptr;
    for (int i = 0; i < num_instr; i++) {
        cur = &decoded[i];
        Dictionary instr;
        instr["offset"] = cur->offset;
        instr["mnemonic"] = (char*)cur->mnemonic.p;
        instr["operands"] = (char*)cur->operands.p;
        instr["size"] = cur->size;
        instr["hex"] = (char*)cur->instructionHex.p;
        a.push_back(instr);
    }

    return a;
}

// disassembly / decomposition
struct dcmp {
    uint8_t *g_bytes_s;
    unsigned int g_num_bytes;
    unsigned long long g_section_base_rva;
    unsigned long long g_image_base;
    _DInst *g_decomposed_instructions;
    unsigned int g_decoded_instr_num;
    _DecodeType g_bit_format;
} dcmp;
bool decompile_bytes_from_rva(unsigned int rva) {
    // calculate byte offset
    unsigned int start_byte = rva - dcmp.g_section_base_rva;
    int size_to_decompile = dcmp.g_num_bytes - start_byte; //NOLINT

    // decompose!
    unsigned int MAX_INSTR = size_to_decompile;
    dcmp.g_decomposed_instructions = new _DInst[MAX_INSTR]; // declared on the heap because yes.
    dcmp.g_decoded_instr_num = 0;
    _CodeInfo ci;
    ci.code = dcmp.g_bytes_s + start_byte;
    ci.codeLen = size_to_decompile;
    ci.codeOffset = rva;
    ci.dt = dcmp.g_bit_format;
    ci.features = DF_NONE;
    _DecodeResult r = distorm_decompose(&ci, dcmp.g_decomposed_instructions, MAX_INSTR, &dcmp.g_decoded_instr_num);
    if (r == DECRES_INPUTERR) {
        delete[] dcmp.g_decomposed_instructions;
        return false;
    }
    return true;
}
bool decompile_bytes_from_byte(unsigned int start_byte, unsigned int rva) {
    // calculate byte offset
    int size_to_decompile = dcmp.g_num_bytes - start_byte; //NOLINT

    // decompose!
    unsigned int MAX_INSTR = size_to_decompile;
    dcmp.g_decomposed_instructions = new _DInst[MAX_INSTR]; // declared on the heap because yes.
    dcmp.g_decoded_instr_num = 0;
    _CodeInfo ci;
    ci.code = dcmp.g_bytes_s + start_byte;
    ci.codeLen = size_to_decompile;
    ci.codeOffset = rva;
    ci.dt = dcmp.g_bit_format;
    ci.features = DF_NONE;
    _DecodeResult r = distorm_decompose(&ci, dcmp.g_decomposed_instructions, MAX_INSTR, &dcmp.g_decoded_instr_num);
    if (r == DECRES_INPUTERR) {
        delete[] dcmp.g_decomposed_instructions;
        return false;
    }
    return true;
}
unsigned int RVA_to_instruction_i(unsigned int rva) {
    for (unsigned int i = 0; i < dcmp.g_decoded_instr_num; i++) {
        if (dcmp.g_decomposed_instructions[i].addr == rva)
            return i;
//        if (g_decomposed_instructions[i].addr > rva) {
//            auto prev_instr = g_decomposed_instructions[i-1];
//            return -1;
//        }
    }
    return -1;
}
void recursive_function_trace(Dictionary dict, unsigned long long rva, unsigned int i) { //NOLINT
    Array calls;
    Dictionary fn_data;
    dict[rva] = fn_data;
    if (i == -1) {
        // either the section didn't decompile properly (misaligned? non-code chunks?) or the RVA is wrong.
        // attempt to decompile from the entry function RVA instead of the whole section...
        if (!decompile_bytes_from_rva(rva))
            return;
        i = RVA_to_instruction_i(rva);
        if (i == -1)
            return;
    }

    // analyze!
    _DInst *cur = nullptr;
    unsigned int starting_i = i;
    while (true)
    {
        cur = &dcmp.g_decomposed_instructions[i];
        if (cur->flags == FLAG_NOT_DECODABLE) {
            fn_data["calls"] = calls;
            fn_data["icount"] = i - starting_i + 1;
            fn_data["size"] = cur->addr - rva + cur->size;
            dict[rva] = fn_data;
            return; // error decoding the machine code
        }

        // determine accessed registers

        switch (cur->opcode) {
            case I_RET: { // end of function body
                fn_data["calls"] = calls;
                fn_data["icount"] = i - starting_i + 1;
                fn_data["size"] = cur->addr - rva + cur->size;
                dict[rva] = fn_data;
                return;
            }
            case I_JMP: {
                if (i == starting_i) { // this is a JMP table thunk for Imports

//                    int op_type1 = cur->ops[0].type;
//                    int op_type2 = cur->ops[1].type;
//                    int op_type3 = cur->ops[2].type;
//                    int op_type4 = cur->ops[3].type;
//                    int target = INSTRUCTION_GET_TARGET(cur);
//                    int imm_addr = cur->imm.addr;
                    Dictionary call_params;

                    unsigned long long rdi_rva = cur->addr + cur->size; // should be equal to INSTRUCTION_GET_TARGET(cur) in this case
                    call_params["jump_to"] = rdi_rva + cur->disp;
                    call_params["address"] = cur->addr;
                    calls.push_back(call_params);
                    fn_data["calls"] = calls;
                    fn_data["is_thunk"] = true;
                    fn_data["icount"] = 1;
                    fn_data["size"] = cur->size;
                    dict[rva] = fn_data;
                    return;
                }
                break;
            }
            case I_CALL: {
                Dictionary call_params;
                int op_type1 = cur->ops[0].type;
//                int op_type2 = cur->ops[1].type;
//                int op_type3 = cur->ops[2].type;
//                int op_type4 = cur->ops[3].type;
                unsigned long long jump_to;
                switch (op_type1) {
                    case O_PC:
                    case O_PTR:
                        jump_to = INSTRUCTION_GET_TARGET(cur);
                        break;
                    case O_DISP: // memory dereference with displacement only, instruction.disp.
                        jump_to = cur->disp - dcmp.g_image_base;
                        break;
                    case O_REG: // dynamic function calls, class methods, callbacks, etc. //NOLINT
                        jump_to = -1;
                        break;
                    default:
                        jump_to = -1;
                        break;
                }
                call_params["address"] = cur->addr;
                call_params["jump_to"] = jump_to;
//                bool jump_is_next_instruction = (jump_to == (cur->addr + cur->size));
                if (jump_to != -1 && !dict.has(jump_to)) {
                    unsigned int jump_i = RVA_to_instruction_i(jump_to);
                    if (jump_i == -1) {
                        Array oob_calls = dict["oob_calls"];
                        oob_calls.push_back(jump_to);
                        dict["oob_calls"] = oob_calls;
                    } else
                        recursive_function_trace(dict, jump_to, jump_i);
                }
                calls.push_back(call_params);
                break;
            }
        }
        i++; // advance instruction
        if (i >= dcmp.g_decoded_instr_num)
            return;
    }
}
Dictionary GDNShell::analyze(PoolByteArray bytes, int bit_format, unsigned long long section_rva, unsigned long long entry_rva, unsigned long long image_base) {
    dcmp.g_bytes_s = (uint8_t*)bytes.read().ptr();
    dcmp.g_num_bytes = bytes.size();
    dcmp.g_section_base_rva = section_rva;
    dcmp.g_image_base = image_base;
    dcmp.g_bit_format = (_DecodeType)bit_format;

    // dictionary defaults
    Dictionary results;
    Array out_of_bound_calls;
    results["oob_calls"] = out_of_bound_calls;

    // decompose!
    if (!decompile_bytes_from_rva(section_rva))
        return results;

    // analyze...
    recursive_function_trace(results, entry_rva, RVA_to_instruction_i(entry_rva));
    delete[] dcmp.g_decomposed_instructions;
    return results;
}

// deeper function logic analysis
long long registers[256];
bool registers_set[256][3];
int classmask_to_register(int class_mask) {
    return log2_32(class_mask);
}
#include <map>
Dictionary GDNShell::deeper_analysis(PoolByteArray bytes, int bit_format, unsigned long long fn_rva, unsigned long long image_base) {
    dcmp.g_bytes_s = (uint8_t*)bytes.read().ptr();
    dcmp.g_num_bytes = bytes.size();
    dcmp.g_image_base = image_base;
    dcmp.g_bit_format = (_DecodeType)bit_format;

    // decompose!
    Dictionary results;
    if (!decompile_bytes_from_byte(0, fn_rva))
        return results;

//    for (int i = 0; i < R_DR7; i++) {
//        registers_set[i][0] = false;
//        registers_set[i][1] = false;
//        registers_set[i][2] = false;
//    }
//    magic_stack.clear();

    // first, analyze the jumps and the calls
    _DInst *cur = nullptr;
    std::map<unsigned long long, std::vector<unsigned int>> jumps;
    std::vector<unsigned int> calls;
    for (int i = 0; i < dcmp.g_decoded_instr_num; i++) {
        cur = &dcmp.g_decomposed_instructions[i];
        auto opcode = (_InstructionType)cur->opcode;
        auto optype = (_OperandType)cur->ops[0].type;
        auto opindex = (_RegisterType)cur->ops[0].index;
        switch (opcode) {
            case I_JA:
            case I_JAE:
            case I_JB:
            case I_JBE:
            case I_JCXZ:
            case I_JECXZ:
            case I_JG:
            case I_JGE:
            case I_JL:
            case I_JLE:
            case I_JMP:
            case I_JMP_FAR:
            case I_JNO:
            case I_JNP:
            case I_JNS:
            case I_JNZ:
            case I_JO:
            case I_JP:
            case I_JRCXZ:
            case I_JS:
            case I_JZ: {
                auto jump_to = INSTRUCTION_GET_TARGET(cur);
                unsigned long long rdi_rva = cur->addr + cur->size;
                bool jump_is_next_instruction = (jump_to == rdi_rva);
                if (jump_is_next_instruction) { // && optype != O_PC
                    switch (optype) {
                        case O_SMEM: {
                            if (cur->ops[0].index == R_RIP)
                                jumps[jump_to + cur->disp].push_back(i - 1);
                            break;
                        }
                        case O_PTR: {
                            auto seg = cur->imm.ptr.seg;
                            auto off = cur->imm.ptr.off;
                            break;
                        }

                    }
                } else
                    jumps[jump_to].push_back(i - 1);
                break;
            }
            case I_CALL:
                calls.push_back(i);
                break;
        }




    }

    // second, for every CALL, traverse the jump tree in regressive order to find the registers used
    for (int i = 0; i < dcmp.g_decoded_instr_num; i++) {
        cur = &dcmp.g_decomposed_instructions[i];


//        if (cur->usedRegistersMask != 0) {
//            auto f_opsize = FLAG_GET_OPSIZE(cur->flags);
//            auto f_addrsize = FLAG_GET_ADDRSIZE(cur->flags);
//            auto f_prefix = FLAG_GET_PREFIX(cur->flags);
//            auto f_privileged = FLAG_GET_PRIVILEGED(cur->flags);
//
//
//            switch (cur->opcode) {
//                case I_PUSH:
//
//                    break;
//                case I_POP:
//                    break;
//            }
//
//
//
//            for (auto reg_op : cur->ops) {
//                if (reg_op.type == O_REG) {
//                    auto reg_index = reg_op.index;
//                    auto reg_size = reg_op.size;
//
//                    int a = 2;
//                }
//            }
//        }
    }

    // cleanup
    delete[] dcmp.g_decomposed_instructions;
    return results;
}

// common Godot funcs/necessary entry points/constructor & deconstructor
void GDNShell::_init() {
    // initialize any variables here
    time_passed = 0.0;
}
void GDNShell::_process(float delta) {
    time_passed += delta;
}
GDNShell::GDNShell() = default;
GDNShell::~GDNShell() = default;
void GDNShell::_register_methods() {
    register_method("_process", &GDNShell::_process);

    register_method("spawn", &GDNShell::spawn);
    register_method("send_string", &GDNShell::send_string);
//    register_method("get_process_status", &GDNShell::get_process_status);
//    register_method("is_waiting_for_input", &GDNShell::send_string);
    register_method("kill", &GDNShell::kill);

    register_method("get_lines_count", &GDNShell::get_lines_count);
    register_method("get_text", &GDNShell::get_text);
    register_method("get_all_text", &GDNShell::get_all_text);
    register_method("clear", &GDNShell::clear);

    register_method("disassemble", &GDNShell::disassemble);
    register_method("analyze", &GDNShell::analyze);
    register_method("deeper_analysis", &GDNShell::deeper_analysis);

//    register_property<GDNShell, RichTextLabel>("console_node", &GDNShell::console_node, empty_node);
//    register_property<GDNShell, String>("APP_NAME", &GDNShell::APP_NAME, "Console");
//    register_property<GDNShell, Array>("LOG", &GDNShell::LOG, Array());

//    register_signal<GDNShell>("console_update", "output_line", GODOT_VARIANT_TYPE_STRING);
    register_signal<GDNShell>("child_process_started");
    register_signal<GDNShell>("child_process_stopped");
    register_signal<GDNShell>("waiting_for_inputs");
}

/////////////

void process_cleanup() {
    std::cerr << "Cleaning up..." << std::endl;
    CloseHandle(hJob);
}
void process_exit() {
    process_cleanup();
}
void process_unexpected_termination() {
    process_cleanup();
}
bool process_setup() {

    // Hook normal exiting functions
    std::atexit(process_exit);
    std::set_terminate(process_unexpected_termination);

    // Create a job object
    hJob = CreateJobObject(nullptr, nullptr);
    if (hJob == nullptr)
    {
        PrintErr("Failed to create job object.");
        return false;
    }

    // Set the job object to terminate all processes when the job object is closed
    JOBOBJECT_EXTENDED_LIMIT_INFORMATION jobInfo;
    memset(&jobInfo, 0, sizeof(JOBOBJECT_EXTENDED_LIMIT_INFORMATION));
    jobInfo.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
    if (!SetInformationJobObject(hJob, JobObjectExtendedLimitInformation, &jobInfo, sizeof(JOBOBJECT_EXTENDED_LIMIT_INFORMATION)))
    {
        PrintErr("Failed to set job object information.");
        CloseHandle(hJob);
        return false;
    }

    return true;
}
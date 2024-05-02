#include "library.h"

#include <string>
#include <Windows.h>
#include <iostream>
#include <mutex>

#include "RichTextLabel.hpp"
#include "TextHistory"

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
void printOutput(char *buffer, DWORD bytesRead) {
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
    int string_start = history.size();
    std::lock_guard<std::mutex> guard(buffer_mutex);
    if (history_linebreaks.empty())
        history_linebreaks.push_back(0); // always have '0' as the first one
    pos = 0;
    while ((pos = formatted.find("\n", pos)) != std::string::npos) {
        pos += 1; // record the START of each line!
        history_linebreaks.push_back(string_start + pos);
    }
    history_lines = history_linebreaks.size();

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
String GDNShell::get_text(int _START_LINE, int _END_LINE) {
    std::lock_guard<std::mutex> guard(buffer_mutex);
    const int LASTLINE = history_linebreaks.size();

    if (history.size() == 0)
        return "";

    // if negative, scroll to the bottom
    if (_START_LINE < 0) {
        _START_LINE += LASTLINE;
        _END_LINE += LASTLINE;
    }

    int s_start;
    if (_START_LINE >= LASTLINE)
        return "";
    else {
        _START_LINE = Math::clamp(_START_LINE, 0, LASTLINE - 1);
        s_start = history_linebreaks.at(_START_LINE);
    }

    int s_end;
    if (_END_LINE >= LASTLINE)
        s_end = history.size();
    else {
        _END_LINE = Math::clamp(_END_LINE, 0, LASTLINE - 1);
        s_end = history_linebreaks.at(_END_LINE);
    }

    s_start = Math::clamp(s_start, 0, int(history.size() - 1));
    s_end = Math::clamp(s_end, 0, int(history.size() - 1));

    if (_START_LINE != _END_LINE && s_start != s_end)
        return history.substr(s_start, s_end - s_start).c_str();
    return "";
}
String GDNShell::get_all_text() {
    std::lock_guard<std::mutex> guard(buffer_mutex);
    int history_size = history.size();
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
            return GetLastError();
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
        return GetLastError();
        auto a = ERROR_INVALID_FUNCTION;
    }
    simpleDebugPrint("GDNShell::spawn 3");

    // Associate the child process with the job object
    if (!AssignProcessToJobObject(hJob, pi.hProcess))
    {
        PrintErr("Failed to assign child process to job object.");
        CloseHandle(pi.hProcess);
        CloseHandle(pi.hThread);
        return GetLastError();
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

// file analysis stuff
_DecodedInst *g_decoded_instructions;
unsigned int g_decoded_instr_num;
unsigned int RVA_to_instruction_i(unsigned int rva) {
    for (unsigned int i = 0; i < g_decoded_instr_num; i++)
        if (g_decoded_instructions[i].offset == rva)
            return i;
    return -1;
}
void recursive_function_trace(Dictionary dict, unsigned int rva, unsigned int section_rva, unsigned int i) {
    Array calls;
    Dictionary fn_data;
    dict[rva] = fn_data;

    // analyze!
    _DecodedInst *cur = nullptr;
    unsigned int starting_i = i;
    while (true)
    {
        cur = &g_decoded_instructions[i];
        if (strcmp((char *) cur->mnemonic.p, "CALL") == 0) {
            Dictionary call_params;
            call_params["address"] = cur->offset;
            if (strncmp((char *) cur->operands.p, "0x", 2) == 0) {
                unsigned int jump_to = std::stoul((char *) cur->operands.p, nullptr, 16);
                call_params["jump_to"] = jump_to;
                if (!dict.has(jump_to)) {
                    unsigned int jump_i = RVA_to_instruction_i(jump_to);
                    if (jump_i > 0 && jump_i < g_decoded_instr_num)
                        recursive_function_trace(dict, jump_to, section_rva, jump_i);
                }
            } else // dynamic function calls, class methods, callbacks, etc.
                call_params["jump_to"] = -1;
            calls.push_back(call_params);
        } else if (strcmp((char *) cur->mnemonic.p, "RET") == 0) {
            fn_data["calls"] = calls;
            fn_data["icount"] = i - starting_i + 1;
            fn_data["size"] = cur->offset - rva + cur->size;
            dict[rva] = fn_data;
            return; // end of function!
        }

        i++; // advance instruction
        if (i >= g_decoded_instr_num)
            return;
    }
}
Dictionary GDNShell::analyze(PoolByteArray bytes, int bit_format, unsigned int section_rva, unsigned int entry_rva) {
    uint8_t *bytes_s;
    bytes_s = (uint8_t*)bytes.read().ptr();
    unsigned int num_bytes = bytes.size();

    // dictionary defaults
    Dictionary functions_data;

    // decompile!
    g_decoded_instructions = new _DecodedInst[num_bytes]; // declared on the heap because yes.
    g_decoded_instr_num = 0;
    _DecodeResult r = distorm_decode(section_rva,
                                     bytes_s,
                                     num_bytes,
                                     (_DecodeType)bit_format,
                                     g_decoded_instructions,
                                     num_bytes,
                                     &g_decoded_instr_num);
    if (r == DECRES_INPUTERR)
        return functions_data;

    // analyze...
    int found_returns = 0;
    int found_calls = 0;
    _DecodedInst *cur = nullptr;

    recursive_function_trace(functions_data, entry_rva, section_rva, RVA_to_instruction_i(entry_rva));
    delete[] g_decoded_instructions;

    return functions_data;
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


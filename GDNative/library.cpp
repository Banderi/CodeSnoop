#include "library.h"

#include <string>
#include <Windows.h>
#include <iostream>
#include <mutex>

#include "RichTextLabel.hpp"
#include "TextHistory"

using namespace godot;

//RichTextLabel *console_node = nullptr;
HANDLE hJob;
HANDLE hInputRead, hInputWrite, hOutputRead, hOutputWrite;
PROCESS_INFORMATION pi;
bool shouldTerminate = false;

std::string history;
std::vector<int> history_linebreaks;
std::mutex buffer_mutex;

std::mutex termination_mutex;

/////////////

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
    int prev_linebreak = 0;
    std::lock_guard<std::mutex> guard(buffer_mutex);
    if (!history_linebreaks.empty())
        prev_linebreak = history_linebreaks.at(history_linebreaks.size() - 1);
    else
        history_linebreaks.push_back(0);
    pos = 0;
    while ((pos = formatted.find("\n", pos)) != std::string::npos) {
        history_linebreaks.push_back(pos);
        pos += 1;
    }

    // Push string into history
    history += formatted;
}
bool redirectStdout () {
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
        printOutput(buffer, bytesRead); // display the output
    }
    return true;
}
void clear_history() {
    std::lock_guard<std::mutex> guard(buffer_mutex);
    history.clear();
    history_linebreaks.clear();
}

void GDNShell::spawn(String path) {
    simpleDebugPrint("--> GDNShell::spawn CALL");
    simpleDebugPrint("GDNShell::spawn 1");

    // Create pipes for input and output
    SECURITY_ATTRIBUTES sa = { sizeof(SECURITY_ATTRIBUTES), nullptr, TRUE };
    if (!CreatePipe(&hOutputRead, &hOutputWrite, &sa, 0) ||
        !CreatePipe(&hInputRead, &hInputWrite, &sa, 0))
    {
        PrintErr("Failed to create pipes.");
        return;
    }

    STARTUPINFO si = { sizeof(STARTUPINFO) };
    simpleDebugPrint("GDNShell::spawn 2");

    // Redirect input and output
    si.dwFlags |= STARTF_USESTDHANDLES;
    si.hStdOutput = hOutputWrite;
    si.hStdError = hOutputWrite;
    si.hStdInput = hInputRead;

    // Set the window style to hide the child process window
    si.dwFlags |= STARTF_USESHOWWINDOW;
    si.wShowWindow = SW_HIDE;

    // Create the child process
    if (!CreateProcess(nullptr, path.alloc_c_string(), nullptr, nullptr, TRUE, CREATE_SUSPENDED, nullptr, nullptr, &si, &pi))
    {
        PrintErr("Failed to create process.");
        return;
    }
    simpleDebugPrint("GDNShell::spawn 3");

    // Associate the child process with the job object
    if (!AssignProcessToJobObject(hJob, pi.hProcess))
    {
        PrintErr("Failed to assign child process to job object.");
        CloseHandle(pi.hProcess);
        CloseHandle(pi.hThread);
        return;
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
    clear_history();
    simpleDebugPrint("GDNShell::spawn 7");

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
}
bool GDNShell::send_string(String string) {
    char *s = string.alloc_c_string();
    DWORD bytesWritten;
    if (!WriteFile(hInputWrite, s, static_cast<DWORD>(strlen(s)), &bytesWritten, nullptr))
    {
        PrintErr("Failed to write to child process.");
        return false;
    }

    std::cout << s << std::endl;
    return true;
}
void GDNShell::kill() {
    simpleDebugPrint("--> GDNShell::kill CALL");
    // Request process termination
    std::lock_guard<std::mutex> guard(termination_mutex);
    shouldTerminate = true;
    simpleDebugPrint("<-- GDNShell::kill RET");
}

int GDNShell::get_lines() {
    std::lock_guard<std::mutex> guard(buffer_mutex);
    return history_linebreaks.size();
}
String GDNShell::fetch_at_line(int _line, int _size) {
    std::lock_guard<std::mutex> guard(buffer_mutex);
    int LASTLINE = history_linebreaks.size();
    int STARTLINE = _line;
    if (_line == -1)
        STARTLINE = LASTLINE - _size;
    int ENDLINE = STARTLINE + _size;
    if (STARTLINE < 0)
        STARTLINE = 0;

    if (STARTLINE >= LASTLINE)
        return "";
    else {
        int s_start = history_linebreaks.at(STARTLINE);
        int s_end;
        if (ENDLINE >= LASTLINE) {
            s_end = history.size();
        } else
            s_end = history_linebreaks.at(ENDLINE);
        if (s_start != 0)
            s_start += 1;
        return history.substr(s_start, s_end - s_start).c_str();
    }
    return "";
}
void GDNShell::clear() {
    clear_history();
}

void GDNShell::_init() {
    // initialize any variables here
    time_passed = 0.0;
//    APP_NAME = "Console";

//    shell_spawn("E:/Git/CppTestApp/cmake-build-debug/CppTestApp.exe");
//    while (true) {
//        if (!shell_step())
//            break;
//    }
//    shell_close();
//    spawn_child("E:/Git/CppTestApp/cmake-build-debug/CppTestApp.exe");
}
void GDNShell::_process(float delta) {
    time_passed += delta;

//    Vector2 new_position = Vector2(10.0 + (10.0 * sin(time_passed * 2.0)), 10.0 + (10.0 * cos(time_passed * 1.5)));

//    set_position(new_position);
//    set_text(to_str(time_passed));

//    auto ss = PoolStringArray();
//    ss.push_back("a");
//    ss.push_back("b");
//    ss.push_back("c");

//    String s = "a";
//    s += "b";

//    append_bbcode(String("a") + String("b"));
}

GDNShell::GDNShell() = default;
GDNShell::~GDNShell() = default;

void GDNShell::_register_methods() {
    register_method("_process", &GDNShell::_process);

    register_method("spawn", &GDNShell::spawn);
    register_method("send_string", &GDNShell::send_string);
    register_method("kill", &GDNShell::kill);

    register_method("get_lines", &GDNShell::get_lines);
    register_method("fetch_at_line", &GDNShell::fetch_at_line);
    register_method("clear", &GDNShell::clear);

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
    CloseHandle(hJob);
    std::cerr << "Cleaning up..." << std::endl;
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


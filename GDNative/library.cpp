#include "library.h"

#include <string>
#include <Windows.h>
#include <iostream>

using namespace godot;

void GDNShell::_register_methods() {
    register_method("_process", &GDNShell::_process);

    register_method("spawn", &GDNShell::spawn);
    register_method("send_input", &GDNShell::send_input);
    register_method("close", &GDNShell::close);

//    register_property<GDNShell, String>("APP_NAME", &GDNShell::APP_NAME, "Console");
//    register_property<GDNShell, Array>("LOG", &GDNShell::LOG, Array());

//    register_signal<GDNShell>("console_update", "output_line", GODOT_VARIANT_TYPE_STRING);
}

GDNShell::GDNShell() {}
GDNShell::~GDNShell() {}

String to_str(int n) {
    return String(std::to_string(n).c_str());
}
String to_str(float n) {
    return String(std::to_string(n).c_str());
}

/////////////

HANDLE hInputRead, hInputWrite, hOutputRead, hOutputWrite;
STARTUPINFO si = { sizeof(STARTUPINFO) };
PROCESS_INFORMATION pi;

char buffer[4096];
DWORD bytesRead;
void GDNShell::spawn() {
    char *path = "E:/Git/CppTestApp/cmake-build-debug/CppTestApp.exe";

    // Create pipes for input and output
    SECURITY_ATTRIBUTES sa = { sizeof(SECURITY_ATTRIBUTES), NULL, TRUE };
    if (!CreatePipe(&hOutputRead, &hOutputWrite, &sa, 0) ||
        !CreatePipe(&hInputRead, &hInputWrite, &sa, 0))
    {
        std::cerr << "Failed to create pipes." << std::endl;
        return;
    }

    // Redirect input and output
    si.dwFlags |= STARTF_USESTDHANDLES;
    si.hStdOutput = hOutputWrite;
    si.hStdError = hOutputWrite;
    si.hStdInput = hInputRead;

    // Set the window style to hide the child process window
    si.dwFlags |= STARTF_USESHOWWINDOW;
    si.wShowWindow = SW_HIDE;

    // Create the child process
    if (!CreateProcess(NULL, path, NULL, NULL, TRUE, 0, NULL, NULL, &si, &pi))
    {
        std::cerr << "Failed to create process." << std::endl;
        return;
    }

    // Close unnecessary pipe handles
    CloseHandle(hOutputWrite);
    CloseHandle(hInputRead);

    // Main loop
    while (true) {
        if (!ReadFile(hOutputRead, buffer, sizeof(buffer), &bytesRead, NULL) || bytesRead == 0)
            break;

        // Process the output as needed
        std::cout.write(buffer, bytesRead);
        std::cout.flush();


        // Check if the child process has exited
        DWORD childStatus;
        if (GetExitCodeProcess(pi.hProcess, &childStatus) && childStatus != STILL_ACTIVE)
            break;
    }
    close();
}
bool GDNShell::send_input(PoolByteArray bytes) {

    std::string userInput = "3"; // testing
    userInput += "\n";  // Add newline character to simulate pressing Enter

    DWORD bytesWritten;
    if (!WriteFile(hInputWrite, userInput.c_str(), static_cast<DWORD>(userInput.length()), &bytesWritten, NULL))
    {
        std::cerr << "Failed to write to child process." << std::endl;
        close();
        return false;
    }

    return true;
}
void GDNShell::close() {
    // Wait for the child process to exit
    WaitForSingleObject(pi.hProcess, INFINITE);

    // Cleanup
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
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
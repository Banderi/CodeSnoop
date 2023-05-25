#include "library.h"

#include <string>
#include <Windows.h>
#include <iostream>

#include <RichTextLabel.hpp>

using namespace godot;

RichTextLabel *console_node = nullptr;

void GDNShell::_register_methods() {
    register_method("_process", &GDNShell::_process);

    register_method("spawn", &GDNShell::spawn);
    register_method("send_string", &GDNShell::send_string);
    register_method("send_input", &GDNShell::send_input);
    register_method("kill", &GDNShell::kill);

//    register_property<GDNShell, RichTextLabel>("console_node", &GDNShell::console_node, empty_node);
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

void PrintErr(const char *err) {
    std::cerr << err << std::endl;
    ERR_PRINT(err);
}

/////////////

HANDLE hInputRead, hInputWrite, hOutputRead, hOutputWrite;
PROCESS_INFORMATION pi;

bool shouldTerminate = false;
void GDNShell::spawn(Variant node) {

    // Register console node
    console_node = Object::cast_to<RichTextLabel>(node.operator Object*());
    if (console_node == nullptr) {
        PrintErr("Passed object is not a RichTextLabel!");
        return;
    }

    char *path = (char*)"E:/Git/CppTestApp/cmake-build-debug/CppTestApp.exe";

    // Create pipes for input and output
    SECURITY_ATTRIBUTES sa = { sizeof(SECURITY_ATTRIBUTES), NULL, TRUE };
    if (!CreatePipe(&hOutputRead, &hOutputWrite, &sa, 0) ||
        !CreatePipe(&hInputRead, &hInputWrite, &sa, 0))
    {
        PrintErr("Failed to create pipes.");
        return;
    }


    STARTUPINFO si = { sizeof(STARTUPINFO) };

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
        PrintErr("Failed to create process.");
        return;
    }

    // Close unnecessary pipe handles
    CloseHandle(hOutputWrite);
    CloseHandle(hInputRead);

    // Main loop
    char buffer[4096];
    DWORD bytesRead;
    while (true) {
        if (!ReadFile(hOutputRead, buffer, sizeof(buffer), &bytesRead, NULL) || bytesRead == 0)
            break;

        // Process the output as needed
        std::cout.write(buffer, bytesRead);
        std::cout.flush();

        console_node->add_text(buffer);

        // Check if the child process has exited
        DWORD childStatus;
        if (GetExitCodeProcess(pi.hProcess, &childStatus) && childStatus != STILL_ACTIVE)
            break;

        // Exit the loop manually
        if (shouldTerminate)
            break;
    }

    if (shouldTerminate) {
        // Manual termination requested, terminate the child process
        TerminateProcess(pi.hProcess, 0);
        shouldTerminate = false;
    } else {
        // Wait for the child process to exit
        WaitForSingleObject(pi.hProcess, INFINITE);
    }

    // Cleanup
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
    console_node = nullptr;
}
bool GDNShell::send_string(String string) {
    std::string userInput = std::string(string.alloc_c_string());
    userInput += "\n";  // Add newline character to simulate pressing Enter
    DWORD bytesWritten;
    if (!WriteFile(hInputWrite, userInput.c_str(), static_cast<DWORD>(userInput.length()), &bytesWritten, NULL))
    {
        PrintErr("Failed to write to child process.");
        return false;
    }

    std::cout << userInput.c_str() << std::endl;
    return true;
}
bool GDNShell::send_input(int scancode) {
//    std::string userInput(1, scancode);
    char ch = (char)scancode;
    DWORD bytesWritten;

    if (!WriteFile(hInputWrite, &ch, sizeof(ch), &bytesWritten, NULL))
    {
        PrintErr("Failed to write to child process.");
        return false;
    }
    std::cout << ch << std::endl;
    return true;
}
void GDNShell::kill() {
    // Attempt to kill child process
    shouldTerminate = true;
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
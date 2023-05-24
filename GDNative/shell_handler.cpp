#include "shell_handler.h"

#include <Windows.h>
#include <iostream>


HANDLE hInputRead, hInputWrite, hOutputRead, hOutputWrite;
STARTUPINFO si = { sizeof(STARTUPINFO) };
PROCESS_INFORMATION pi;

bool shell_spawn(char *path)
{
    // Create pipes for input and output
//    HANDLE hInputRead, hInputWrite, hOutputRead, hOutputWrite;
    SECURITY_ATTRIBUTES sa = { sizeof(SECURITY_ATTRIBUTES), NULL, TRUE };
    if (!CreatePipe(&hOutputRead, &hOutputWrite, &sa, 0) ||
        !CreatePipe(&hInputRead, &hInputWrite, &sa, 0))
    {
        std::cerr << "Failed to create pipes." << std::endl;
        return false;
    }

    // Configure the startup info and process info
//    STARTUPINFO si = { sizeof(STARTUPINFO) };
//    PROCESS_INFORMATION pi;

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
        return false;
    }

    // Close unnecessary pipe handles
    CloseHandle(hOutputWrite);
    CloseHandle(hInputRead);

    // Read and display output from the child process
//    char buffer[4096];
//    DWORD bytesRead;
//    while (true)
//    {
//        if (!ReadFile(hOutputRead, buffer, sizeof(buffer), &bytesRead, NULL) || bytesRead == 0)
//            break;
//
//        // Process the output as needed
//        std::cout.write(buffer, bytesRead);
//        std::cout.flush();
//    }
//
//    // Wait for the child process to exit
//    WaitForSingleObject(pi.hProcess, INFINITE);
//
//    // Cleanup
//    CloseHandle(pi.hProcess);
//    CloseHandle(pi.hThread);

    return true;
}

char buffer[4096];
DWORD bytesRead;
bool shell_step() {
    if (!ReadFile(hOutputRead, buffer, sizeof(buffer), &bytesRead, NULL) || bytesRead == 0)
        return false;

    // Process the output as needed
    std::cout.write(buffer, bytesRead);
    std::cout.flush();


    // Check if the child process has exited
    DWORD childStatus;
    if (GetExitCodeProcess(pi.hProcess, &childStatus) && childStatus != STILL_ACTIVE)
        return false;

//    // Read user input and send it to the child process
//    std::string userInput;
//    std::getline(std::cin, userInput);

//    userInput += "\n";  // Add newline character to simulate pressing Enter
//
//    DWORD bytesWritten;
//    if (!WriteFile(hInputWrite, userInput.c_str(), static_cast<DWORD>(userInput.length()), &bytesWritten, NULL))
//    {
//        std::cerr << "Failed to write to child process." << std::endl;
//        return false;
//    }


    return true;
}
bool shell_send_input(std::string userInput) {
    userInput += "\n";  // Add newline character to simulate pressing Enter

    DWORD bytesWritten;
    if (!WriteFile(hInputWrite, userInput.c_str(), static_cast<DWORD>(userInput.length()), &bytesWritten, NULL))
    {
        std::cerr << "Failed to write to child process." << std::endl;
        return false;
    }

    return true;
}

void shell_close() {
    // Wait for the child process to exit
    WaitForSingleObject(pi.hProcess, INFINITE);

    // Cleanup
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
}
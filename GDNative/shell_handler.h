#ifndef GDNATIVE_SHELL_HANDLER_H
#define GDNATIVE_SHELL_HANDLER_H

#include <string>

bool shell_spawn(char *path);
bool shell_step();
bool shell_send_input(std::string userInput);
void shell_close();

#endif //GDNATIVE_SHELL_HANDLER_H

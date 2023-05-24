#include "library.h"

#include <string>
#include "shell_handler.h"

using namespace godot;

void GDNShell::_register_methods() {
    register_method("_process", &GDNShell::_process);

    register_method("spawn", &GDNShell::spawn);
//    register_method("step", &GDNShell::step);
    register_method("send_line", &GDNShell::send_line);
    register_method("close", &GDNShell::close);

//    register_property<GDNShell, String>("APP_NAME", &GDNShell::APP_NAME, "Console");
    register_property<GDNShell, Array>("LOG", &GDNShell::LOG, Array());
//    register_signal<GDNShell>("test_signal", "test_return_string", GODOT_VARIANT_TYPE_STRING);
}

GDNShell::GDNShell() {}
GDNShell::~GDNShell() {}

String to_str(int n) {
    return String(std::to_string(n).c_str());
}
String to_str(float n) {
    return String(std::to_string(n).c_str());
}


void GDNShell::spawn() {


    shell_spawn("E:/Git/CppTestApp/cmake-build-debug/CppTestApp.exe");
    while (true) {
        if (!shell_step())
            break;
    }
    shell_close();

//    emit_signal("test_signal", "TEST SIGNAL!!!!!");
//    return "test!!!!";
}
//bool GDNShell::step() {
//    if (!shell_step()) {
//        shell_close();
//        return false;
//    }
//    return true;
//}
bool GDNShell::send_line(String s) {
    if (!shell_send_input("3")) {
        shell_close();
        return false;
    }
    return true;
}
void GDNShell::close() {
    shell_close();
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
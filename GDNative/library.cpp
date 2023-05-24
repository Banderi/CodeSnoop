#include "library.h"
#include <string>

using namespace godot;

void GDNShell::_register_methods() {
    register_method("_process", &GDNShell::_process);
    register_property<GDNShell, String>("APP_NAME", &GDNShell::APP_NAME, "Console");
    register_property<GDNShell, Array>("LOG", &GDNShell::LOG, Array());
}

GDNShell::GDNShell() {}
GDNShell::~GDNShell() {}

String to_str(int n) {
    return String(std::to_string(n).c_str());
}
String to_str(float n) {
    return String(std::to_string(n).c_str());
}


void GDNShell::_init() {
    // initialize any variables here
    time_passed = 0.0;
//    APP_NAME = "Console";
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
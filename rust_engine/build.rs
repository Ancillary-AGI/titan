use std::env;
use std::path::PathBuf;

fn main() {
    // Generate C bindings
    let crate_dir = env::var("CARGO_MANIFEST_DIR").unwrap();
    
    cbindgen::Builder::new()
        .with_crate(crate_dir)
        .with_language(cbindgen::Language::C)
        .with_style(cbindgen::Style::Both)
        .with_include_guard("TITAN_ENGINE_H")
        .with_pragma_once(true)
        .with_documentation(true)
        .with_cpp_compat(true)
        .generate()
        .expect("Unable to generate bindings")
        .write_to_file("titan_engine.h");
    
    // Tell cargo to invalidate the built crate whenever the wrapper changes
    println!("cargo:rerun-if-changed=src/ffi.rs");
    println!("cargo:rerun-if-changed=build.rs");
    
    // Link system libraries based on platform
    if cfg!(target_os = "windows") {
        println!("cargo:rustc-link-lib=user32");
        println!("cargo:rustc-link-lib=gdi32");
        println!("cargo:rustc-link-lib=opengl32");
    } else if cfg!(target_os = "macos") {
        println!("cargo:rustc-link-lib=framework=Cocoa");
        println!("cargo:rustc-link-lib=framework=OpenGL");
        println!("cargo:rustc-link-lib=framework=CoreVideo");
    } else if cfg!(target_os = "linux") {
        println!("cargo:rustc-link-lib=X11");
        println!("cargo:rustc-link-lib=GL");
        println!("cargo:rustc-link-lib=EGL");
    }
    
    // GStreamer linking
    if cfg!(feature = "media") {
        pkg_config::Config::new()
            .atleast_version("1.0")
            .probe("gstreamer-1.0")
            .unwrap();
        
        pkg_config::Config::new()
            .atleast_version("1.0")
            .probe("gstreamer-video-1.0")
            .unwrap();
        
        pkg_config::Config::new()
            .atleast_version("1.0")
            .probe("gstreamer-audio-1.0")
            .unwrap();
    }
}
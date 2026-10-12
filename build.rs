use std::env;
use std::process::Command;

fn r2_env(key: &str) -> String {
    String::from_utf8_lossy(
        &Command::new("radare2")
            .args(["-H", key])
            .output()
            .unwrap_or_else(|_| panic!("failed to run radare2 -H {key}"))
            .stdout,
    )
    .trim()
    .to_string()
}

fn main() {
    let target = env::var("TARGET").unwrap_or_default();
    let is_linux = target.contains("linux");

    let ldflags = r2_env("R2_LDFLAGS");
    // R2_LDFLAGS only carries -L paths; R2_LIBS has the full -lr_* list
    let mut libs = String::new();
    let rlibs = r2_env("R2_LIBS");
    libs.push_str(&rlibs);

    for flag in ldflags.split_whitespace() {
        if let Some(path) = flag.strip_prefix("-L") {
            println!("cargo:rustc-link-search={path}");
        }
    }

    for flag in libs.split_whitespace() {
        if let Some(lib) = flag.strip_prefix("-l") {
            // libdl does not exist on macos/windows
            if lib == "dl" && !is_linux {
                continue;
            }
            println!("cargo:rustc-link-lib={lib}");
        }
    }

    if target.contains("windows") {
        println!("cargo:rustc-link-lib=shlwapi");
    }

    if target.contains("apple") {
        // cdylib plugins must tolerate unresolved r_* symbols (resolved
        // from the host radare2 process at dlopen time)
        println!("cargo:rustc-link-arg=-Wl,-undefined,dynamic_lookup");
    }

    let r2_version = r2_env("R2_VERSION");
    let r2_abiversion: u32 = r2_env("R2_ABIVERSION")
        .parse()
        .expect("R2_ABIVERSION is not a valid u32");

    println!("cargo:rustc-env=R2_VERSION={r2_version}");
    println!("cargo:rustc-env=R2_ABIVERSION={r2_abiversion}");

    println!("cargo:rerun-if-changed=build.rs");
}

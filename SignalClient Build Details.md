#  How to build Signal Client


1) Clone the `https://github.com/signalapp/libsignal-client` repository into the base folder
2) Inside the `libsignal-client` folder run `cargo lipo --release`
3) Add `$libsignal-client/universal/release/libsignal_ffi.a` to the targets Build Phases under 'Link binary with Libraries'
4) Add the /Swift/SignalClient folder to the project

Further details: https://github.com/TimNN/cargo-lipo

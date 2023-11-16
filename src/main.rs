use clap::{arg, Arg, Command, Parser};
use rayon::prelude::*;
use std::sync::{Arc, Mutex};

#[derive(Parser)]
struct Args {
    #[arg(value_delimiter=' ', num_args=1..)]
    signatures: Vec<String>,
}

fn main() {
    let args = Args::parse();
    // up to max 16 signatures
    if args.signatures.len() > 16 {
        panic!("Too many signatures");
    }
    // minimum 2 signatures
    if args.signatures.len() < 2 {
        panic!("Too few signatures");
    }

    let nums = args
        .signatures
        .iter()
        // clean if start with 0x
        .map(|s| s.trim_start_matches("0x"))
        .map(|s| u64::from_str_radix(s, 16).unwrap())
        .collect::<Vec<u64>>();

    // Number of batches to run in parallel
    let num_batches = 8;
    // Shared variable to indicate if the input has been found
    let found = Arc::new(Mutex::new(false));

    (0..num_batches).into_par_iter().for_each(|i| {
        let mut mod_start: u64 = 268435456 / num_batches * i + 1;
        let mod_end: u64 = 268435456 / num_batches * (i + 1);

        loop {
            let altered = nums
                .iter()
                .map(|n| (n % mod_start) & 0xF)
                .collect::<Vec<u64>>();
            let unique = altered.iter().collect::<std::collections::HashSet<_>>();

            let mut _found = found.lock().unwrap();
            if *_found {
                break;
            }
            if unique.len() == altered.len() {
                *_found = true;
                println!("Found magic modulo: {}", mod_start);
                println!("Selector indices given magic modulo: {:?}", altered);
                break;
            } else if mod_start == mod_end {
                break;
            }
            mod_start += 1;
        }
    });
}

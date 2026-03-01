#![allow(while_true)] // shut the fuck up
#![allow(unused_imports)] // didn't ask???

use ruszt::{bash, builtin, variable, assoc::Assoc};
use std::ffi::CStr;
use std::fs::File;
use std::io::Read;
use std::str;
use std::collections::HashMap;

#[builtin]
fn array(args: Vec<&CStr>) -> i32 {
	// let meow = ruszt::get_assoc(c"str").unwrap();
	// let hash = (*meow).value as *mut bash::HASH_TABLE;
	// let map = ruszt::assoc::new_hashmap_idk_what_im_doing(hash);
	let map = Assoc::from_var_name("str").unwrap();

	// for i in {0..(*hash).nbuckets} {
	// 	let item = *(*hash).bucket_array.wrapping_add(i as usize);
	// 	if (item != std::ptr::null_mut()) {
	// 		println!("{:?}: {:?}", std::ffi::CStr::from_ptr((*item).key), std::ffi::CStr::from_ptr((*item).data as *const i8));
	// 	}
	// }


	// for a in args {
	// 	println!("{}", a.to_string_lossy());
	// }
	let path: String = args[0].to_string_lossy().to_string();
	let mut file = File::open(path).unwrap();
	let mut contents = String::new();
	file.read_to_string(&mut contents);

	// PASS 1: expand includes
	let mut contents_inc = String::new();
	let mut prev_match = 0;
	
	for i in contents.match_indices("{{#") {
		let mut iter = contents[i.0 + 3..].chars().peekable();
		let mut path = unpackTagName(iter);
		contents_inc.push_str(&contents[prev_match..i.0]);
		
		let mut file_ = File::open(path.clone()).unwrap();
		file_.read_to_string(&mut contents_inc);
		// println!("{:?}", i.next());
		prev_match = i.0 + path.len() + 5; // 3 chrs in front, 2 in the back
	}
	contents_inc.push_str(&contents[prev_match..]);
	contents = contents_inc;

	// PASS 2: iterators and conditionals
	for i in contents.match_indices("{{start") {
		let mut iter = contents[i.0 + 8..].chars().peekable();
		// let mut path = String::new();
		let mut name = unpackTagName(iter);
		match name.chars().nth(0).unwrap() {
			'?' => {
				println!("cond");
				let mut tag = String::from("{{else ");
				tag.push_str(&name);
				tag.push_str("}}");
				for i in contents.match_indices(&tag) {
					println!("{:?}", i.0);
				}
				let mut tag = String::from("{{end ");
				tag.push_str(&name);
				tag.push_str("}}");
				for i in contents.match_indices(&tag) {
					println!("{:?}", i.0);
				}

			},
			'_' => {
				println!("iter");
			},
			_ => {
				println!("???");
			}
		}
		println!("{}",name);
	}

	// PASS 3: the everything else
	let mut line = String::new();
	let mut iter = contents.chars().peekable();
	while let Some(chr) = iter.next() {
		match chr {
			'{' => {
				if iter.peek() == Some(&'{') {
					iter.next(); // discard the 2nd '{'
					let mut tag = String::new();
					while let Some(chr) = iter.next() {
						match chr {
							'\n' => {
								line.push_str(&tag.to_string()); // unclosed tag, push it back
								break;
							},
							'}' => {
								if iter.peek() == Some(&'}') {
									iter.next(); // discard the 2nd '}'
									break;
								}
							},
							_ => {
								tag.push(chr);
							}
						}
					}

					// line.push_str(&parseTag(tag, &map));
					match tag.chars().nth(0).unwrap() {
						'.' => {
							// TODO: html_encode this
							// let tag_ = String::from(tag);
							let res = map.get(&tag[1..]).unwrap().unwrap();
							// let tag_ = String::from(tag);
							// let res = map.get(&tag[1..].into());
							// let res = map.get(&"a");
							// if res.is_some() {
							// 	line.push_str(res.unwrap());
							// } else {
							line.push_str(&res.to_string_lossy().to_string());
							// }
						},
						'@' => {
							let res = map.get(&tag[1..]).unwrap().unwrap();
							// if res.is_some() {
							// 	line.push_str(res.unwrap());
							// } else {
							// line.push_str(res.to_string_lossy().into_owned().as_ref());
							// }
							line.push_str(&res.to_string_lossy().to_string());
						}
						_ => {
							println!("???")
						}
					}
				}
			},
			'\n' => {
				println!("{}", line);
				line = String::new();
			}
			_ => {
				line.push(chr);
			}
		}
	}
	bash::EXIT_SUCCESS.cast_signed()
}

fn unpackTagName(mut iter: std::iter::Peekable<std::str::Chars>) -> String {
	let mut tagname = String::new();
	while true {
		let j = iter.next();
		match j {
			Some('}') => {
				if iter.peek() == Some(&'}') {
					break;
				}
				tagname.push('}');
			},
			Some('\n') => {
				break; // TODO: indicate failure here
			},
			// TODO: break on EOF
			// Null => {
			// 	break;
			// },
			_ => {
				tagname.push(j.unwrap());
			}
		}
	};
	tagname
}

// fn parseTag(tag: String, map: &HashMap<String,String>) -> String {
// 	let id = tag.chars().nth(0).unwrap();
// 	match id {
// 		'.' => {
// 			// TODO: html_encode this
// 			let res = map.get(&tag[1..].to_string());
// 			if res.is_some() {
// 				return res.unwrap().clone();
// 			} else {
// 				return "{{}}".to_string();
// 			}
// 		},
// 		'@' => {
// 			let res = map.get(&tag[1..].to_string());
// 			if res.is_some() {
// 				return res.unwrap().clone();
// 			} else {
// 				return "{{}}".to_string();
// 			}
// 		}
// 		_ => {
// 			if (&tag[0..5] == "start") {
// 				println!("start");
// 			} else if (&tag[0..4] == "else") {
// 				println!("else");
// 			} else if (&tag[0..3] == "end") {
// 				println!("end");
// 			} else {
// 				println!("??? {}", tag);
// 			}
// 		}
// 	}
// 	String::new()
// }

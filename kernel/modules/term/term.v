// term.v: Terminal stuff.
// Code is governed by the GPL-2.0 license.
// Copyright (C) 2021-2022 The Vinix authors.

module term

import klock
import dev.fbdev.api
import dev.fbdev.simple
import limine
import flanterm

__global (
	flanterm_ctx &flanterm.Context

	terminal_print_lock klock.Lock
	terminal_rows       = u64(0)
	terminal_cols       = u64(0)
	framebuffer_tag     = &limine.LimineFramebuffer(unsafe { nil })
	framebuffer_width   = u64(0)
	framebuffer_height  = u64(0)
)

@[cinit]
@[_linker_section: '.requests']
__global (
	volatile fb_req = limine.LimineFramebufferRequest{
		response: unsafe { nil }
	}
)

pub fn initialise() {
	framebuffer_tag = unsafe { fb_req.response.framebuffers[0] }
	framebuffer_width = framebuffer_tag.width
	framebuffer_height = framebuffer_tag.height

	flanterm_ctx = unsafe { C.flanterm_fb_init(nil, nil,
											   framebuffer_tag.address, framebuffer_width, framebuffer_height, framebuffer_tag.pitch,
											   framebuffer_tag.red_mask_size, framebuffer_tag.red_mask_shift,
											   framebuffer_tag.green_mask_size, framebuffer_tag.green_mask_shift,
											   framebuffer_tag.blue_mask_size, framebuffer_tag.blue_mask_shift,
											   nil,
											   nil, nil,
											   nil, nil,
											   nil, nil,
											   nil, 0, 0, 1,
											   0, 0,
											   0) }

	terminal_rows = C.flanterm_get_rows(flanterm_ctx)
	terminal_cols = C.flanterm_get_cols(flanterm_ctx)
}

pub fn framebuffer_init() {
   	// Map the framebuffer both in the higher half and the lower half for the
	// kernel, which we use for calling the stivale2 terminal.
	int_addr := u64(framebuffer_tag.address)
	for i := u64(0); i < framebuffer_width * 4 * framebuffer_tag.pitch; i += page_size {
		kernel_pagemap.flag_page(int_addr + i,               (1 << 7) | (1 << 3) | 3) or {}
		kernel_pagemap.flag_page(int_addr - higher_half + i, (1 << 7) | (1 << 3) | 3) or {}
	}

	sfb_config := simple.SimpleFBConfig {
		physical_address: framebuffer_tag.address,
		width: u32(framebuffer_width),
		height: u32(framebuffer_height),
		stride: u32(framebuffer_tag.pitch),
		bits_per_pixel: u32(framebuffer_tag.bpp),
		red: api.FBBitfield {
			offset: framebuffer_tag.red_mask_shift,
			length: framebuffer_tag.red_mask_size,
			msb_right: 0,
		},
		green: api.FBBitfield {
			offset: framebuffer_tag.green_mask_shift,
			length: framebuffer_tag.green_mask_size,
			msb_right: 0,
		},
		blue: api.FBBitfield {
			offset: framebuffer_tag.blue_mask_shift,
			length: framebuffer_tag.blue_mask_size,
			msb_right: 0,
		},
		transp: api.FBBitfield {
			offset: 0,
			length: 0,
			msb_right: 0,
		},
	}

	simple.register_simple_framebuffer(sfb_config)
}

pub fn print(s voidptr, len u64) {
	terminal_print_lock.acquire()
	C.flanterm_write(mut flanterm_ctx, s, len)
	terminal_print_lock.release()
}

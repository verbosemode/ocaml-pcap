(*
 * Copyright (c) 2012 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

let major_version = 2

let minor_version = 4

type endian = | Big | Little

let string_of_endian = function
| Big    -> "big"
| Little -> "little"

module LE = struct
  let endian = Little

  cstruct pcap_header {
    uint32_t magic_number;   (* magic number *)
    uint16_t version_major;  (* major version number *)
    uint16_t version_minor;  (* minor version number *)
    uint32_t thiszone;       (* GMT to local correction *)
    uint32_t sigfigs;        (* accuracy of timestamps *)
    uint32_t snaplen;        (* max length of captured packets, in octets *)
    uint32_t network         (* data link type *)
  } as little_endian

  cstruct pcap_packet {
    uint32_t ts_sec;         (* timestamp seconds *)
    uint32_t ts_usec;        (* timestamp microseconds *)
    uint32_t incl_len;       (* number of octets of packet saved in file *)
    uint32_t orig_len        (* actual length of packet *)
  } as little_endian

end

module BE = struct
  let endian = Big

  cstruct pcap_header {
    uint32_t magic_number;   (* magic number *)
    uint16_t version_major;  (* major version number *)
    uint16_t version_minor;  (* minor version number *)
    uint32_t thiszone;       (* GMT to local correction *)
    uint32_t sigfigs;        (* accuracy of timestamps *)
    uint32_t snaplen;        (* max length of captured packets, in octets *)
    uint32_t network         (* data link type *)
  } as big_endian

  cstruct pcap_packet {
    uint32_t ts_sec;         (* timestamp seconds *)
    uint32_t ts_usec;        (* timestamp microseconds *)
    uint32_t incl_len;       (* number of octets of packet saved in file *)
    uint32_t orig_len        (* actual length of packet *)
  } as big_endian
end

module type HDR = sig
  val endian: endian

end

let magic_number = 0xa1b2c3d4l

let detect buf =
  let le_magic = LE.get_pcap_header_magic_number buf in
  let be_magic = BE.get_pcap_header_magic_number buf in
  if le_magic = magic_number then Some (module LE: HDR)
  else if be_magic = magic_number then Some (module BE: HDR)
  else None

let packets h =
  let module H = (val h : HDR) in
  let open LE in (* XXX *)
  Cstruct.iter 
    (fun buf -> Some (sizeof_pcap_packet + (Int32.to_int (get_pcap_packet_incl_len buf))))
    (fun buf -> buf, (Cstruct.shift buf sizeof_pcap_packet))

let network_ethernet = 1l
(** pcap_header network value indicating ethernet *)

;  bits.ash -- bit access for decompression
;
;  This file is part of the UCL data compression library.
;
;  Copyright (C) 1996-2006 Markus Franz Xaver Johannes Oberhumer
;  All Rights Reserved.
;
;  The UCL library is free software; you can redistribute it and/or
;  modify it under the terms of the GNU General Public License as
;  published by the Free Software Foundation; either version 2 of
;  the License, or (at your option) any later version.
;
;  The UCL library is distributed in the hope that it will be useful,
;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;  GNU General Public License for more details.
;
;  You should have received a copy of the GNU General Public License
;  along with the UCL library; see the file COPYING.
;  If not, write to the Free Software Foundation, Inc.,
;  59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
;  Markus F.X.J. Oberhumer              Jens Medoch
;  <markus@oberhumer.com>               <jssg@users.sourceforge.net>
;  http://www.oberhumer.com/opensource/ucl/
;

#ifndef _MR3K_STD_CONF_
#define _MR3K_STD_CONF_


;//////////////////////////////////////
;// register defines
;//////////////////////////////////////

#define src         a0
#define dst         a2

#define src_ilen    t0
#define bb          t1
#define ilen        t2
#define last_m_off  t3
#define m_len       t4
#define bc          t5

#define var         v0
#define m_off       v1
#define m_pos       v1


;//////////////////////////////////////
;// optimized branch macros
;//////////////////////////////////////

beqz2gb     MACRO   reg,label,nrv_bb
    IF (!small) && (nrv_bb == 8)
            beqz    reg,label+4
            andi    var,bb,0x007F
    ELSE
            beqz    reg,label
            nop
    ENDIF
beqz2gb     ENDM

b2gb        MACRO   label,nrv_bb
    IF (!small)
            b       label+4
        IF (nrv_bb == 8)
            andi    var,bb,0x007F
        ELSE ;(nrv_bb == 32)
            addiu   bc,-1
        ENDIF
    ELSE
            b       label
            nop
    ENDIF
b2gb        ENDM


;//////////////////////////////////////
;// ucl memcpy
;//////////////////////////////////////

uclmcpy     MACRO   retoffset,nrv_bb
#   ifdef FAST
            slti    var,m_off,4
            bnez    var,prepbytecpy
            addiu   m_len,1
            subu    m_pos,dst,m_off
wordchk:
            slti    var,m_len,4
            bnez    var,bytecopy+4
            lwr     var,0(m_pos)
            lwl     var,3(m_pos)
            addiu   m_len,-4
            swr     var,0(dst)
            swl     var,3(dst)
            addiu   m_pos,4
            bnez    m_len,wordchk
            addiu   dst,4
            b2gb    retoffset,nrv_bb
prepbytecpy:
#   else
            addiu   m_len,1
#   endif
            subu    m_pos,dst,m_off
bytecopy:
            lbu     var,0(m_pos)
            addiu   m_len,-1
            sb      var,0(dst)
            addiu   m_pos,1
            bnez    m_len,bytecopy
            addiu   dst,1
            b2gb    retoffset,nrv_bb
uclmcpy     ENDM


;//////////////////////////////////////
;// init decompressor
;//////////////////////////////////////

init        MACRO   nrv_bb
            move    bb,zero
    IF (nrv_bb == 32)
            move    bc,bb
    ENDIF
            li      last_m_off,1
            move    src_ilen,src
init        ENDM


;//////////////////////////////////////
;// 32bit getbit macro
;//////////////////////////////////////

gbit_le32   MACRO
    IF (!small)
            addiu   bc,-1
    ENDIF
            bgez    bc,\@z
            srlv    var,bb,bc
            li      bc,31
            lwr     bb,0(src_ilen)
            lwl     bb,3(src_ilen)
            addiu   src_ilen,4
            srlv    var,bb,bc
\@z:
    IF (small)
            jr      ra
    ENDIF
            andi    var,0x0001
gbit_le32   ENDM


;//////////////////////////////////////
;// 8bit getbit macro
;//////////////////////////////////////

gbit_8      MACRO
    IF (!small)
            andi    var,bb,0x007F
    ENDIF
            bnez    var,\@x
            sll     bb,1
            lbu     var,0(src_ilen)
            addiu   src_ilen,1
            sll     var,1
            addiu   bb,var,1
\@x:
            srl     var,bb,8
    IF (small)
            jr      ra
    ENDIF
            andi    var,0x0001
gbit_8      ENDM


;//////////////////////////////////////
;// getbit call macro for small version
;//////////////////////////////////////

gbit_call   MACRO   subroutine,nrv_bb
            bal     subroutine
    IF (nrv_bb == 8)
            andi    var,bb,0x007F
    ELSE
            addiu   bc,-1
    ENDIF
gbit_call   ENDM


#endif  //_MR3K_STD_CONF_
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "perliol.h"

IV push_utf8(pTHX_ PerlIO* f, const char* mode) {
    PerlIO_funcs* encoding = PerlIO_find_layer(aTHX_ "utf8_strict", 11, 1);
    return PerlIO_push(aTHX_ f, encoding, mode, NULL) == f ? 0 : -1;
}

IV push_encoding_sv(pTHX_ PerlIO* f, const char* mode, SV* encoding) {
    PerlIO_funcs* layer = PerlIO_find_layer(aTHX_ "encoding", 8, 1);
    return PerlIO_push(aTHX_ f, layer , mode, encoding) == f ? 0 : -1;
}

IV push_encoding_pvn(pTHX_ PerlIO* f, const char* mode, const char* encoding_name, Size_t encoding_length) {
	SV* encoding = sv_2mortal(newSVpvn(encoding_name, encoding_length));
	return push_encoding_sv(aTHX_ f, mode, encoding);
}

static IV PerlIOBom_pushed(pTHX_ PerlIO *f, const char *mode, SV *arg, PerlIO_funcs *tab)
{
	if (PerlIOValid(f) && PerlIO_fast_gets(f)) {
		PerlIO_fill(f);
		Size_t count = PerlIO_get_cnt(f);
		if (count > 4) {
			char* buffer = PerlIO_get_ptr(f);
			if (memcmp(buffer, "\xEF\xBB\xBF", 3) == 0) {
				PerlIO_set_ptrcnt(f, buffer + 3, count - 3);
				return push_utf8(aTHX_ f, mode);
			}
			else if (memcmp(buffer, "\x00\x00\xFE\xFF", 4) == 0) {
				PerlIO_set_ptrcnt(f, buffer + 4, count - 4);
				return push_encoding_pvn(aTHX_ f, mode, STR_WITH_LEN("UTF32-BE"));
			}
			else if (memcmp(buffer, "\xFF\xFE\x00\x00", 4) == 0) {
				PerlIO_set_ptrcnt(f, buffer + 4, count - 4);
				return push_encoding_pvn(aTHX_ f, mode, STR_WITH_LEN("UTF32-LE"));
			}
			else if (memcmp(buffer, "\xFE\xFF", 2) == 0) {
				PerlIO_set_ptrcnt(f, buffer + 2, count - 2);
				return push_encoding_pvn(aTHX_ f, mode, STR_WITH_LEN("UTF16-BE"));
			}
			else if (memcmp(buffer, "\xFF\xFE", 2) == 0) {
				PerlIO_set_ptrcnt(f, buffer + 2, count - 2);
				return push_encoding_pvn(aTHX_ f, mode, STR_WITH_LEN("UTF16-LE"));
			}
			else if (arg && SvOK(arg)) {
				STRLEN len;
				const char* fallback = SvPV(arg, len);
				if (
					len >= 4 &&
					(memcmp(fallback, "utf", 3) == 0 || memcmp(fallback, "UTF", 3) == 0) &&
					fallback[3] == '8' || (fallback[3] == '-' && fallback[4] == '8')
				) {
					return push_utf8(aTHX_ f, mode);
				}
				else {
					return push_encoding_sv(aTHX_ f, mode, arg);
				}
			}
			else {
				errno = EILSEQ;
				return -1;
			}
		}
	}
	return -1;
}

PerlIO_funcs PerlIO_bom = {
    sizeof(PerlIO_funcs),
    "bom",
    0,
    0,
    PerlIOBom_pushed,
    NULL,
#if PERL_VERSION >= 14
    PerlIOBase_open,
#else
    PerlIOBuf_open,
#endif
};

MODULE = PerlIO::bom				PACKAGE = PerlIO::bom

PROTOTYPES: DISABLED

BOOT:
    PerlIO_define_layer(aTHX_ &PerlIO_bom);


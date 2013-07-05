unit uconst;

interface

type
  _PEmitInts = ^_TEmitInts;
  _TEmitInts = (inone, iread, iwrite, imov, iclosure, ijmp, ijse, ijbe, ijs, ijb, ije,
    ijne, isub, iadd, imul, idiv, inum, iident, icmp, ihalt, icall, iret, ipush,
    ipop, pnil, pboolean, ptrue, pfalse, pint, pstring, pfunc, pobject,
    pfuncaddr, iebp, inop, imod, igetobjv, inewobj, isetobjv,
    ivalue, itheend);
  PEmitInts = ^TEmitInts;

  TEmitInts = packed record
    Ints: _TEmitInts;
    sInstr: string;
    iInstr: integer;
  end;

  PValue = ^TValue;

  TValue = record
    _Type, _CodeType: _TEmitInts;
    _Int, _iident: integer;
    _String: string;
    _Boolean: boolean;
    _Value: PValue;
    _Id: string;
    _i: Integer;
  end;

var
  PrintInts: array[_TEmitInts] of string = (
    'none',
    'read',
    'write',
    'mov',
    'closure',
    'jmp',
    'jse',
    'jbe',
    'js',
    'jb',
    'je',
    'jne',
    'sub',
    'add',
    'mul',
    'div',
    'num',
    'ident',
    'cmp',
    'halt',
    'call',
    'ret',
    'push',
    'pop',
    'nil',
    'boolean',
    'true',
    'false',
    'int',
    'string',
    'function',
    'object',
    'funcaddr',
    'iebp',
    'nop',
    'mod',
    'getobjv',
    'newobj',
    'setobjv',
    'value',
    'theend'
    );

implementation

end.
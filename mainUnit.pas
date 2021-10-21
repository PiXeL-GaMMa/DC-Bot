//
// A demonstration dc++ bot - I will update occasionally demonstrating data processing tactics and/or protocol features as requested.
// Author: Colin J.D. Stewart
// License: MIT - If you find something useful, a thanks or attribution would be nice :)
// DOGE coin tips welcome: DBxYmNXLSGwS8M3uYHyMr9BM7xbZPwZ2Xa
//
//
// Current features/demonstrations:
// * The use of ZLib for the $ZOn| protocol feature.
//
// Last update: 21.10.2021
//
unit mainUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, ScktComp,

  System.ZLib;

type
  //
  // our simple test bot class using a basic TClientSocket
  //
  TTestBot = class(TClientSocket)
  private
    F_zon: boolean;

    F_zs: TZStreamRec;
    F_zout: RawByteString;

    F_zbuf: RawByteString;
    F_buf: RawByteString;
  public
    property ZOn: boolean read F_zon write F_zon;
    property ZS: TZStreamRec read F_zs;
    property ZOut: RawByteString read F_zout;
    property ZBuffer: RawByteString read F_zbuf;
    property Buffer: RawByteString read F_buf;

    constructor Create(AOwner: TComponent);

    procedure processCommandLine(command_line: RawByteString);
    procedure processZBuffer;
    procedure processBuffer;

    procedure appendZBuffer(input: RawByteString);
    procedure appendBuffer(input: RawByteString);
  end;


  TMainFRM = class(TForm)
    memoLog: TMemo;
    btnConnect: TButton;
    procedure btnConnectClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    client: TTestBot;

  public
    { Public declarations }

    procedure readEvent(Sender: TObject; Socket: TCustomWinSocket);
    procedure errorEvent(Sender: TObject; Socket: TCustomWinSocket; ErrorEvent: TErrorEvent; var ErrorCode: Integer);
  end;

var
  MainFRM: TMainFRM;

implementation

{$R *.dfm}


//
// creation of our testbot class, just init some variables.
//
constructor TTestBot.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  F_zbuf := '';
  F_buf := '';
  F_zon := false;
end;

//
// these following append functions are again just examples...
// best would be to create a custom data buffer class instead of using rawbytestring
//
procedure TTestBot.appendZBuffer(input: RawByteString);
begin
  F_zbuf := F_zbuf + input;
end;

procedure TTestBot.appendBuffer(input: RawByteString);
begin
  F_buf := F_buf + input;
end;

//
// input command+data is processed here (or not processed for this demo)
//
procedure TTestBot.processCommandLine(command_line: RawByteString);
begin
  MainFRM.memoLog.Lines.Add('> Command Line: '+command_line);

  // obviously here we should properly parse the commands and data, but this is just a demonstration

  if Copy(command_line, 1, 5) = '$Lock' then begin
    Socket.SendText('$Supports NoGetINFO NoHello BotList MCTo HubTopic FailOver TTHSearch TTHS NickRule SearchRule HubURL ZPipe0 |$Key ABC123|$ValidateNick BotName|');
  end else if Copy(command_line, 1, 6) = '$Hello' then begin
    Socket.SendText('$Version 1,0091|$GetNickList|$MyINFO $ALL BotName <ClientType V:1.0.0.0,M:A,H:1/0/0,S:10>$ $1000' + Char(1) + '$$0$|');
  end else if Copy(command_line, 1, 4) = '$ZOn' then begin
    // reset and initialize the stream struct
    F_zs.next_in := nil;
    F_zs.avail_in := 0;
    F_zs.zalloc := nil;
    F_zs.zfree := nil;
    F_zs.opaque := 0;
    inflateInit(F_zs);

    F_zbuf := '';
    F_zon := true;
  end;
end;

//
// the following procedure keeps adding additional data to deflate until the stream end is found
// the decompressed data and additional left over data is placed back into normal buffer and then sent for processing
//
procedure TTestBot.processZBuffer;
const
  BLOCK_SIZE = 1024*32;
var
  rc: Integer;
begin
  repeat
    F_zs.next_in := PByte(@F_zbuf[1]);
    F_zs.avail_in := Length(F_zbuf);

    SetLength(F_zout, F_zs.total_out + BLOCK_SIZE);
    F_zs.next_out := PByte(@F_zout[1]) + F_zs.total_out;

    F_zs.avail_out := BLOCK_SIZE;
    rc := inflate(F_zs, Z_SYNC_FLUSH);

    Delete(F_zbuf, 1, F_zs.next_in - PByte(@F_zbuf[1]));
  until (rc = Z_STREAM_ERROR) or (rc <> Z_OK) or (F_zs.avail_out <> 0);

  if rc = Z_STREAM_END then begin
    F_Buf := F_Buf + copy(F_zout,1,F_zs.total_out);
    F_zout := '';

    F_Buf := F_Buf + F_zbuf;
    F_zbuf := '';

    F_zon := false;
    inflateEnd(F_zs);

    processBuffer();
  end else if rc <> Z_OK then begin
    // error ?
  end;
end;


//
// simple procedure that seperates input by nmdc pipe char then calls another procedure to process the data
//
procedure TTestBot.processBuffer;
var
  pipe_pos: Integer;
  command_line: RawByteString;
begin
  pipe_pos := System.Pos('|', F_buf);
  while pipe_pos > 0 do begin
    command_line := System.Copy(F_buf, 1, pipe_pos);
    System.Delete(F_buf, 1, pipe_pos);

    processCommandLine(command_line);
    pipe_pos := System.Pos('|', F_buf);

    if F_zon then begin
      F_zbuf := F_buf;
      F_buf := '';
      processZBuffer();
      break;
    end;
  end;
end;


//
// simple onRead event, that will call specific procedure depending if ZOn is enabled
//
procedure TMainFRM.readEvent(Sender: TObject; Socket: TCustomWinSocket);
var
  cli: TTestBot;
begin
  cli := TTestBot(Sender);
  if cli.ZOn = true then begin
    cli.appendZBuffer(Socket.ReceiveText);
    cli.processZBuffer();
  end else begin
    cli.appendBuffer(Socket.ReceiveText);
    cli.processBuffer();
  end;
end;


//
// a socket error occured???
//
procedure TMainFRM.errorEvent(Sender: TObject; Socket: TCustomWinSocket; ErrorEvent: TErrorEvent; var ErrorCode: Integer);
begin
  // do something here ?
  memoLog.Lines.Add('> Error: '+IntToStr(ErrorCode));
end;


//
// very simple client/socket usage, this is not part of the demonstration, please use better libraries for sockets
// or alternavely, roll your own
//
procedure TMainFRM.btnConnectClick(Sender: TObject);
begin
  client.Host := '127.0.0.1';
  client.Port := 411;

  client.OnRead := readEvent;
  client.OnError := errorEvent;

  client.Open;
end;

procedure TMainFRM.FormCreate(Sender: TObject);
begin
  client := TTestBot.Create(self);
end;

procedure TMainFRM.FormDestroy(Sender: TObject);
begin
  client.Free;
end;

end.

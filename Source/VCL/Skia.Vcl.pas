{************************************************************************}
{                                                                        }
{                              Skia4Delphi                               }
{                                                                        }
{ Copyright (c) 2011-2022 Google LLC.                                    }
{ Copyright (c) 2021-2022 Skia4Delphi Project.                           }
{                                                                        }
{ Use of this source code is governed by a BSD-style license that can be }
{ found in the LICENSE file.                                             }
{                                                                        }
{************************************************************************}
unit Skia.Vcl;

interface

{$SCOPEDENUMS ON}

uses
  { Delphi }
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Math,
  System.Messaging,
  System.Generics.Collections,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.ExtCtrls,

  { Skia }
  Skia;

type
  ESkVcl              = class(Exception);
  ESkBitmapHelper     = class(ESkVcl);
  ESkPersistentData   = class(ESkVcl);
  ESkTextSettingsInfo = class(ESkVcl);
  ESkLabel            = class(ESkVcl);

  TSkDrawProc = reference to procedure(const ACanvas: ISkCanvas);

  { TSkBitmapHelper }

  TSkBitmapHelper = class helper for TBitmap
  strict private
    procedure FlipPixels(const AWidth, AHeight: Integer; const ASrcPixels: PByte; const ASrcStride: Integer; const ADestPixels: PByte; const ADestStride: Integer); inline;
  public
    procedure SkiaDraw(const AProc: TSkDrawProc; const AStartClean: Boolean = True);
    function ToSkImage: ISkImage;
  end;

  { TSkPersistentData }

  TSkPersistentData = class(TPersistent)
  strict private
    FChanged: Boolean;
    FCreated: Boolean;
    FIgnoringAllChanges: Boolean;
    FOnChange: TNotifyEvent;
    FUpdatingCount: Integer;
    function GetUpdating: Boolean;
  protected
    procedure DoAssign(ASource: TPersistent); virtual;
    procedure DoChanged; virtual;
    function GetHasChanged: Boolean; virtual;
    function SetValue(var AField: Byte; const AValue: Byte): Boolean; overload;
    function SetValue(var AField: Word; const AValue: Word): Boolean; overload;
    function SetValue(var AField: Cardinal; const AValue: Cardinal): Boolean; overload;
    function SetValue(var AField: Boolean; const AValue: Boolean): Boolean; overload;
    function SetValue(var AField: Integer; const AValue: Integer): Boolean; overload;
    function SetValue(var AField: Int64; const AValue: Int64): Boolean; overload;
    function SetValue(var AField: Single; const AValue: Single; const AEpsilon: Single = 0.0): Boolean; overload;
    function SetValue(var AField: Double; const AValue: Double; const AEpsilon: Double = 0.0): Boolean; overload;
    function SetValue(var AField: TBytes; const AValue: TBytes): Boolean; overload;
    function SetValue(var AField: string; const AValue: string): Boolean; overload;
    function SetValue<T>(var AField: T; const AValue: T): Boolean; overload;
    property Created: Boolean read FCreated;
    property UpdatingCount: Integer read FUpdatingCount;
  public
    procedure AfterConstruction; override;
    procedure Assign(ASource: TPersistent); override; final;
    procedure BeginUpdate; overload;
    procedure BeginUpdate(const AIgnoreAllChanges: Boolean); overload; virtual;
    procedure Change; virtual;
    procedure EndUpdate; overload;
    procedure EndUpdate(const AIgnoreAllChanges: Boolean); overload; virtual;
    property HasChanged: Boolean read GetHasChanged;
    property Updating: Boolean read GetUpdating;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  TSkDrawEvent = procedure(ASender: TObject; const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single) of object;
  TSkDrawCacheKind = (Never, Raster, Always);

  { TSkCustomControl }

  TSkCustomControl = class abstract(TGraphicControl)
  strict private
    FDrawBuffer: HBITMAP;
    FDrawBufferData: Pointer;
    FDrawBufferStride: Integer;
    FDrawCached: Boolean;
    FDrawCacheKind: TSkDrawCacheKind;
    FOnDraw: TSkDrawEvent;
    FOpacity: Byte;
    procedure CreateBuffer(const AMemDC: HDC; out ABuffer: HBITMAP; out AData: Pointer; out AStride: Integer);
    procedure DeleteBuffers;
    procedure SetDrawCacheKind(const AValue: TSkDrawCacheKind);
    procedure SetOnDraw(const AValue: TSkDrawEvent);
    procedure SetOpacity(const AValue: Byte);
  {$IF CompilerVersion < 33}
  strict protected
    FScaleFactor: Single;
    procedure ChangeScale(M, D: Integer); override;
  {$ENDIF}
  strict protected
    procedure Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single); virtual;
    procedure DrawDesignBorder(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
    function NeedsRedraw: Boolean; virtual;
    procedure Paint; override; final;
    procedure Resize; override;
    property DrawCacheKind: TSkDrawCacheKind read FDrawCacheKind write SetDrawCacheKind default TSkDrawCacheKind.Raster;
    property OnDraw: TSkDrawEvent read FOnDraw write SetOnDraw;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Redraw;
    {$IF CompilerVersion < 33}
    property ScaleFactor: Single read FScaleFactor;
    {$ENDIF}
  published
    property Align;
    property Anchors;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Opacity: Byte read FOpacity write SetOpacity default 255;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Touch;
    property Visible;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnGesture;
    property OnMouseActivate;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
  end;

  { TSkPaintBox }

  TSkPaintBox = class(TSkCustomControl)
  published
    property OnDraw;
  end;

  TSkSvgSource = type string;
  TSkSvgWrapMode = (Default, Fit, FitCrop, Original, OriginalCenter, Place, Stretch, Tile);

  { TSkSvgBrush }

  TSkSvgBrush = class(TPersistent)
  strict private
    const
      DefaultGrayScale = False;
      DefaultWrapMode = TSkSvgWrapMode.Fit;
  strict private
    FDOM: ISkSVGDOM;
    FGrayScale: Boolean;
    FOnChanged: TNotifyEvent;
    FOriginalSize: TSizeF;
    FOverrideColor: TAlphaColor;
    FSource: TSkSvgSource;
    FWrapMode: TSkSvgWrapMode;
    function GetDOM: ISkSVGDOM;
    function GetOriginalSize: TSizeF;
    function IsGrayScaleStored: Boolean;
    function IsOverrideColorStored: Boolean;
    function IsWrapModeStored: Boolean;
    procedure SetGrayScale(const AValue: Boolean);
    procedure SetOverrideColor(const AValue: TAlphaColor);
    procedure SetSource(const AValue: TSkSvgSource);
    procedure SetWrapMode(const AValue: TSkSvgWrapMode);
  strict protected
    procedure DoAssign(ASource: TSkSvgBrush); virtual;
    procedure DoChanged; virtual;
    function HasContent: Boolean; virtual;
    function MakeDOM: ISkSVGDOM; virtual;
    procedure RecreateDOM;
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    function Equals(AObject: TObject): Boolean; override;
    procedure Render(const ACanvas: ISkCanvas; const ADestRect: TRectF; const AOpacity: Single);
    property DOM: ISkSVGDOM read GetDOM;
    property OriginalSize: TSizeF read GetOriginalSize;
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  published
    property GrayScale: Boolean read FGrayScale write SetGrayScale stored IsGrayScaleStored;
    property OverrideColor: TAlphaColor read FOverrideColor write SetOverrideColor stored IsOverrideColorStored;
    property Source: TSkSvgSource read FSource write SetSource;
    property WrapMode: TSkSvgWrapMode read FWrapMode write SetWrapMode stored IsWrapModeStored;
  end;

  { TSkSvg }

  TSkSvg = class(TSkCustomControl)
  strict private
    FSvg: TSkSvgBrush;
    procedure SetSvg(const AValue: TSkSvgBrush);
    procedure SvgChanged(ASender: TObject);
  strict protected
    function CreateSvgBrush: TSkSvgBrush; virtual;
    procedure Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Svg: TSkSvgBrush read FSvg write SetSvg;
    property OnDraw;
  end;

  { TSkCustomWinControl }

  TSkCustomWinControl = class abstract(TCustomControl)
  strict private
    FBackgroundBuffer: TBitmap;
    FDrawBuffer: HBITMAP;
    FDrawBufferData: Pointer;
    FDrawBufferStride: Integer;
    FDrawCached: Boolean;
    FDrawCacheKind: TSkDrawCacheKind;
    FDrawParentInBackground: Boolean;
    FOnDraw: TSkDrawEvent;
    FOpacity: Byte;
    procedure CreateBuffer(const AMemDC: HDC; out ABuffer: HBITMAP; out AData: Pointer; out AStride: Integer);
    procedure DeleteBuffers;
    procedure DrawParentImage(ADC: HDC; AInvalidateParent: Boolean = False);
    function GetOpaqueParent: TWinControl;
    procedure SetDrawCacheKind(const AValue: TSkDrawCacheKind);
    procedure SetDrawParentInBackground(const AValue: Boolean);
    procedure SetOnDraw(const AValue: TSkDrawEvent);
    procedure SetOpacity(const AValue: Byte);
    procedure WMEraseBkgnd(var AMessage: TWMEraseBkgnd); message WM_ERASEBKGND;
  {$IF CompilerVersion < 33}
  strict protected
    FScaleFactor: Single;
    procedure ChangeScale(M, D: Integer); override;
  {$ENDIF}
  strict protected
    procedure Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single); virtual;
    procedure DrawDesignBorder(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
    function NeedsRedraw: Boolean; virtual;
    procedure Paint; override; final;
    procedure Resize; override;
    property DrawCacheKind: TSkDrawCacheKind read FDrawCacheKind write SetDrawCacheKind default TSkDrawCacheKind.Raster;
    property DrawParentInBackground: Boolean read FDrawParentInBackground write SetDrawParentInBackground;
    property OnDraw: TSkDrawEvent read FOnDraw write SetOnDraw;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Redraw;
    {$IF CompilerVersion < 33}
    property ScaleFactor: Single read FScaleFactor;
    {$ENDIF}
  published
    property Align;
    property Anchors;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Opacity: Byte read FOpacity write SetOpacity default 255;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Touch;
    property Visible;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnGesture;
    property OnMouseActivate;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
  end;

  { TSkCustomAnimation }
  TSkCustomAnimation = class(TSkPersistentData)
  public const
    DefaultFrameRate = 60;
  public class var
    FrameRate: Integer;
  protected const
    DefaultAutoReverse = False;
    DefaultDelay = 0;
    DefaultEnabled = True;
    DefaultInverse = False;
    DefaultLoop = True;
    DefaultPause = False;
    DefaultSpeed = 1;
    DefaultStartFromCurrent = False;
    DefaultStartProgress = 0;
    DefaultStopProgress = 1;
    ProgressEpsilon = 0;
    SpeedEpsilon = 1E-3;
    SpeedRoundTo = -3;
    TimeEpsilon = 1E-3;
    TimeRoundTo = -3;
  strict private
    type
      TProcess = class
      strict private
        // Unsafe referece for TSkAnimation in list
        FAniList: TList<Pointer>;
        FAniProcessingList: TList<Pointer>;
        FAnimation: TTimer;
        FPerformanceFrequency: Int64;
        FTime: Double;
        procedure DoAdd(const AAnimation: TSkCustomAnimation);
        procedure DoRemove(const AAnimation: TSkCustomAnimation);
        function GetTick: Double;
        procedure OnProcess(ASender: TObject);
      strict private
        class var FProcess: TProcess;
        class destructor Destroy;
      public
        constructor Create;
        destructor Destroy; override;
        class procedure Add(const AAnimation: TSkCustomAnimation); static;
        class procedure Remove(const AAnimation: TSkCustomAnimation); static;
      end;
  strict private
    FAllowAnimation: Boolean;
    FAutoReverse: Boolean;
    FCurrentTime: Double;
    FCurrentTimeChanged: Boolean;
    FDelay: Double;
    FDelayTime: Double;
    FDuration: Double;
    FEnabled: Boolean;
    FEnabledChanged: Boolean;
    FInverse: Boolean;
    FLoop: Boolean;
    FNeedStart: Boolean;
    FNeedStartRepaint: Boolean;
    [unsafe] FOwner: TComponent;
    FPause: Boolean;
    FProcessDuration: Double;
    FProcessing: Boolean;
    FProcessTime: Double;
    FProgress: Double;
    FRunning: Boolean;
    FSavedInverse: Boolean;
    FSavedProgress: Double;
    FSpeed: Double;
    FStartFromCurrent: Boolean;
    FStartProgress: Double;
    FStopProgress: Double;
    FTickCount: Integer;
    function CanProcessing: Boolean;
    function DoSetCurrentTime(const AValue: Double): Boolean;
    procedure InternalStart(const ACanProcess: Boolean);
    function IsDelayStored: Boolean;
    function IsProgressStored: Boolean;
    function IsSpeedStored: Boolean;
    function IsStartProgressStored: Boolean;
    function IsStopProgressStored: Boolean;
    procedure ProcessTick(ADeltaTime: Double);
    procedure SetAllowAnimation(const AValue: Boolean);
    procedure SetCurrentTime(const AValue: Double);
    procedure SetDelay(const AValue: Double);
    procedure SetEnabled(const AValue: Boolean);
    procedure SetLoop(const AValue: Boolean);
    procedure SetPause(const AValue: Boolean);
    procedure SetProcessing(const AValue: Boolean);
    procedure SetProgress(const AValue: Double);
    procedure SetRunning(const AValue: Boolean);
    procedure SetSpeed(const AValue: Double);
    procedure SetStartProgress(const AValue: Double);
    procedure SetStartValues(const ADelayTime: Double; const AStartAtEnd: Boolean);
    procedure SetStopProgress(const AValue: Double);
    procedure UpdateCurrentTime(const AIsRunning, ARecalcProcessDuration: Boolean); inline;
  private
    property SavedProgress: Double read FSavedProgress write FSavedProgress;
  protected
    procedure BeforePaint;
    procedure DoAssign(ASource: TPersistent); override;
    procedure DoChanged; override;
    procedure DoFinish; virtual; abstract;
    procedure DoProcess; virtual; abstract;
    procedure DoStart; virtual; abstract;
    function GetDuration: Double;
    procedure SetDuration(const AValue: Double);
    property AllowAnimation: Boolean read FAllowAnimation write SetAllowAnimation;
    property Owner: TComponent read FOwner;
    property Processing: Boolean read FProcessing;
  public
    constructor Create(const AOwner: TComponent);
    destructor Destroy; override;
    function Equals(AObject: TObject): Boolean; override;
    procedure Start; virtual;
    procedure Stop; virtual;
    procedure StopAtCurrent; virtual;
    property AutoReverse: Boolean read FAutoReverse write FAutoReverse default DefaultAutoReverse;
    /// <summary> Current time of the animation in seconds </summary>
    property CurrentTime: Double read FCurrentTime write SetCurrentTime stored False nodefault;
    /// <summary> Delay in seconds to start the animation </summary>
    property Delay: Double read FDelay write SetDelay stored IsDelayStored;
    /// <summary> Duration in seconds </summary>
    property Duration: Double read GetDuration;
    /// <summary> Enables the animation to run automatically (in the next control's paint). </summary>
    property Enabled: Boolean read FEnabled write SetEnabled default DefaultEnabled;
    property Inverse: Boolean read FInverse write FInverse default DefaultInverse;
    property Loop: Boolean read FLoop write SetLoop default DefaultLoop;
    property Pause: Boolean read FPause write SetPause default DefaultPause;
    /// <summary> Normalized CurrentTime (value between 0..1) </summary>
    property Progress: Double read FProgress write SetProgress stored IsProgressStored;
    property Running: Boolean read FRunning;
    property Speed: Double read FSpeed write SetSpeed stored IsSpeedStored;
    property StartFromCurrent: Boolean read FStartFromCurrent write FStartFromCurrent default DefaultStartFromCurrent;
    property StartProgress: Double read FStartProgress write SetStartProgress stored IsStartProgressStored;
    property StopProgress: Double read FStopProgress write SetStopProgress stored IsStopProgressStored;
  end;

  TSkAnimationDrawEvent = procedure(ASender: TObject; const ACanvas: ISkCanvas; const ADest: TRectF; const AProgress: Double; const AOpacity: Single) of object;
  TSkAnimationDrawProc = reference to procedure(const ACanvas: ISkCanvas; const ADest: TRectF; const AProgress: Double; const AOpacity: Single);

  { TSkCustomAnimatedControl }

  TSkCustomAnimatedControl = class abstract(TSkCustomWinControl)
  strict protected
    type
      TAnimationBase = class(TSkCustomAnimation)
      strict private
        FInsideDoProcess: Boolean;
      protected
        procedure DoChanged; override;
        procedure DoFinish; override;
        procedure DoProcess; override;
        procedure DoStart; override;
      end;
  strict private
    FAbsoluteVisible: Boolean;
    FAbsoluteVisibleCached: Boolean;
    FOnAnimationDraw: TSkAnimationDrawEvent;
    FOnAnimationFinish: TNotifyEvent;
    FOnAnimationProcess: TNotifyEvent;
    FOnAnimationStart: TNotifyEvent;
    procedure CheckAbsoluteVisible;
    procedure CheckDuration;
    procedure CMParentVisibleChanged(var AMessage: TMessage); message CM_PARENTVISIBLECHANGED;
    procedure CMVisibleChanged(var AMessage: TMessage); message CM_VISIBLECHANGED;
    function GetAbsoluteVisible: Boolean;
    procedure SetOnAnimationDraw(const AValue: TSkAnimationDrawEvent);
  strict protected
    FAnimation: TAnimationBase;
    function CanRunAnimation: Boolean; virtual;
    procedure CheckAnimation;
    function CreateAnimation: TAnimationBase; virtual; abstract;
    procedure DoAnimationChanged; virtual;
    procedure DoAnimationFinish; virtual;
    procedure DoAnimationProcess; virtual;
    procedure DoAnimationStart; virtual;
    procedure Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single); override;
    procedure ReadState(AReader: TReader); override;
    procedure RenderFrame(const ACanvas: ISkCanvas; const ADest: TRectF; const AProgress: Double; const AOpacity: Single); virtual;
    property AbsoluteVisible: Boolean read GetAbsoluteVisible;
    property OnAnimationDraw: TSkAnimationDrawEvent read FOnAnimationDraw write SetOnAnimationDraw;
    property OnAnimationFinish: TNotifyEvent read FOnAnimationFinish write FOnAnimationFinish;
    property OnAnimationProcess: TNotifyEvent read FOnAnimationProcess write FOnAnimationProcess;
    property OnAnimationStart: TNotifyEvent read FOnAnimationStart write FOnAnimationStart;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  { TSkAnimatedPaintBox }

  TSkAnimatedPaintBox = class(TSkCustomAnimatedControl)
  public
    type
      { TAnimation }

      TAnimation = class(TAnimationBase)
      protected const
        DefaultDuration = 1;
      strict private
        function IsDurationStored: Boolean;
      strict protected
        procedure DoAssign(ASource: TPersistent); override;
      public
        constructor Create(const AOwner: TComponent);
        function Equals(AObject: TObject): Boolean; override;
      published
        property AutoReverse;
        property Delay;
        property Duration: Double read GetDuration write SetDuration stored IsDurationStored;
        property Enabled;
        property Inverse;
        property Loop;
        property Progress;
        property Speed;
        property StartFromCurrent;
        property StartProgress;
        property StopProgress;
      end;
  strict private
    function GetAnimation: TAnimation;
    procedure ReadAnimate(AReader: TReader);
    procedure ReadDuration(AReader: TReader);
    procedure ReadLoop(AReader: TReader);
    procedure SetAnimation(const AValue: TAnimation);
  strict protected
    function CreateAnimation: TSkCustomAnimatedControl.TAnimationBase; override;
    procedure DefineProperties(AFiler: TFiler); override;
  published
    property Animation: TAnimation read GetAnimation write SetAnimation;
    property OnAnimationDraw;
    property OnAnimationFinish;
    property OnAnimationProcess;
    property OnAnimationStart;
  end;

  { TSkAnimatedPaintBoxHelper }

  TSkAnimatedPaintBoxHelper = class helper for TSkAnimatedPaintBox
  strict protected
    function RunningAnimation: Boolean; deprecated 'Use Animation.Running instead';
  public
    function Animate: Boolean; deprecated 'Use Animation.Enabled instead';
    function Duration: Double; deprecated 'Use Animation.Duration instead';
    function FixedProgress: Boolean; deprecated 'Use Animation.Enabled instead';
    function Loop: Boolean; deprecated 'Use Animation.Loop instead';
    function Progress: Double; deprecated 'Use Animation.Progress instead';
  end;

  TSkAnimatedImageWrapMode = (Fit, FitCrop, Original, OriginalCenter, Place, Stretch);

  { TSkAnimatedImage }

  TSkAnimatedImage = class(TSkCustomAnimatedControl)
  public
    type
      { TAnimation }

      TAnimation = class(TAnimationBase)
      published
        property AutoReverse;
        property Delay;
        property Duration;
        property Enabled;
        property Inverse;
        property Loop;
        property Progress;
        property Speed;
        property StartFromCurrent;
        property StartProgress;
        property StopProgress;
      end;

      { TSource }

      TSource = class(TPersistent)
      strict private
        FData: TBytes;
        FOnChange: TNotifyEvent;
        procedure SetData(const AValue: TBytes);
      public
        constructor Create(const AOnChange: TNotifyEvent);
        procedure Assign(ASource: TPersistent); override;
        function Equals(AObject: TObject): Boolean; override;
        property Data: TBytes read FData write SetData;
      end;

      { TFormatInfo }

      TFormatInfo = record
        Description: string;
        Extensions: TArray<string>;
        Name: string;
        constructor Create(const AName, ADescription: string; const AExtensions: TArray<string>);
      end;

      { TAnimationCodec }

      TAnimationCodec = class
      strict protected
        function GetDuration: Double; virtual; abstract;
        function GetFPS: Double; virtual; abstract;
        function GetIsStatic: Boolean; virtual; abstract;
        function GetSize: TSizeF; virtual; abstract;
      public
        procedure Render(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single); virtual; abstract;
        procedure SeekFrameTime(const ATime: Double); virtual; abstract;
        class function SupportedFormats: TArray<TFormatInfo>; virtual; abstract;
        class function TryDetectFormat(const ABytes: TBytes; out AFormat: TFormatInfo): Boolean; virtual; abstract;
        class function TryMakeFromStream(const AStream: TStream; out ACodec: TAnimationCodec): Boolean; virtual; abstract;
        property Duration: Double read GetDuration;
        property FPS: Double read GetFPS;
        property IsStatic: Boolean read GetIsStatic;
        property Size: TSizeF read GetSize;
      end;

      TAnimationCodecClass = class of TAnimationCodec;
  strict private
    class var
      FRegisteredCodecs: TArray<TAnimationCodecClass>;
  strict private
    FCodec: TAnimationCodec;
    FSource: TSource;
    FWrapMode: TSkAnimatedImageWrapMode;
    function GetAnimation: TAnimation;
    function GetOriginalSize: TSizeF;
    procedure ReadData(AStream: TStream);
    procedure ReadLoop(AReader: TReader);
    procedure ReadOnAnimationFinished(AReader: TReader);
    procedure ReadOnAnimationProgress(AReader: TReader);
    procedure SetAnimation(const AValue: TAnimation);
    procedure SetSource(const AValue: TSource);
    procedure SetWrapMode(const AValue: TSkAnimatedImageWrapMode);
    procedure SourceChange(ASender: TObject);
    procedure WriteData(AStream: TStream);
  strict protected
    function CreateAnimation: TSkCustomAnimatedControl.TAnimationBase; override;
    procedure DefineProperties(AFiler: TFiler); override;
    procedure Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single); override;
    procedure RenderFrame(const ACanvas: ISkCanvas; const ADest: TRectF; const AProgress: Double; const AOpacity: Single); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure LoadFromFile(const AFileName: string);
    procedure LoadFromStream(const AStream: TStream);
    class procedure RegisterCodec(const ACodecClass: TAnimationCodecClass); static;
    class property RegisteredCodecs: TArray<TAnimationCodecClass> read FRegisteredCodecs;
    property OriginalSize: TSizeF read GetOriginalSize;
  published
    property Animation: TAnimation read GetAnimation write SetAnimation;
    property Source: TSource read FSource write SetSource;
    property WrapMode: TSkAnimatedImageWrapMode read FWrapMode write SetWrapMode default TSkAnimatedImageWrapMode.Fit;
    property OnAnimationDraw;
    property OnAnimationFinish;
    property OnAnimationProcess;
    property OnAnimationStart;
  end;

  { TSkAnimatedImageHelper }

  TSkAnimatedImageHelper = class helper for TSkAnimatedImage
  strict protected
    function Duration: Double; deprecated 'Use Animation.Duration instead';
  public
    function FixedProgress: Boolean; deprecated 'Use Animation.Enabled instead';
    function Loop: Boolean; deprecated 'Use Animation.Loop instead';
    function Progress: Double; deprecated 'Use Animation.Progress instead';
    function RunningAnimation: Boolean; deprecated 'Use Animation.Running instead';
  end;

  { TSkFontComponent }

  TSkFontComponent = class(TSkPersistentData)
  public
    type
      TSkFontSlant = (Regular, Italic, Oblique);
      TSkFontStretch = (UltraCondensed, ExtraCondensed, Condensed, SemiCondensed, Regular, SemiExpanded, Expanded, ExtraExpanded, UltraExpanded);
      TSkFontWeight = (Thin, UltraLight, Light, SemiLight, Regular, Medium, Semibold, Bold, UltraBold, Black, UltraBlack);
  strict protected
    const
      DefaultFamilies = '';
      DefaultSize = 14;
      DefaultSlant = TSkFontSlant.Regular;
      DefaultStretch = TSkFontStretch.Regular;
      DefaultWeight = TSkFontWeight.Regular;
  strict private
    FFamilies: string;
    FSize: Single;
    FSlant: TSkFontSlant;
    FStretch: TSkFontStretch;
    FWeight: TSkFontWeight;
    procedure SetFamilies(const AValue: string);
    procedure SetSize(const AValue: Single);
    procedure SetSlant(const AValue: TSkFontSlant);
    procedure SetStretch(const AValue: TSkFontStretch);
    procedure SetWeight(const AValue: TSkFontWeight);
  strict protected
    procedure AssignTo(ADest: TPersistent); override;
    procedure DoAssign(ASource: TPersistent); override;
    function IsFamiliesStored: Boolean; virtual;
    function IsSizeStored: Boolean; virtual;
  public
    constructor Create;
    function Equals(AObject: TObject): Boolean; override;
  published
    property Families: string read FFamilies write SetFamilies stored IsFamiliesStored;
    property Size: Single read FSize write SetSize stored IsSizeStored;
    property Slant: TSkFontSlant read FSlant write SetSlant default DefaultSlant;
    property Stretch: TSkFontStretch read FStretch write SetStretch default DefaultStretch;
    property Weight: TSkFontWeight read FWeight write SetWeight default DefaultWeight;
  end;

  TSkTextHorzAlign = (Center, Leading, Trailing, Justify);
  TSkTextVertAlign = (Center, Leading, Trailing);
  TSkTextTrimming = (None, Character, Word);
  TSkStyledSetting = (Family, Size, Style, FontColor, Other);
  TSkStyledSettings = set of TSkStyledSetting;

  { TSkTextSettings }

  TSkTextSettings = class(TSkPersistentData)
  public
    type
      { TDecorations }

      TDecorations = class(TSkPersistentData)
      strict protected
        const
          DefaultColor = TAlphaColors.Null;
          DefaultDecorations = [];
          DefaultStrokeColor = TAlphaColors.Null;
          DefaultStyle = TSkTextDecorationStyle.Solid;
          DefaultThickness = 1;
      strict private
        FColor: TAlphaColor;
        FDecorations: TSkTextDecorations;
        FStrokeColor: TAlphaColor;
        FStyle: TSkTextDecorationStyle;
        FThickness: Single;
        procedure SetColor(const AValue: TAlphaColor);
        procedure SetDecorations(const AValue: TSkTextDecorations);
        procedure SetStrokeColor(const AValue: TAlphaColor);
        procedure SetStyle(const AValue: TSkTextDecorationStyle);
        procedure SetThickness(const AValue: Single);
      strict protected
        procedure DoAssign(ASource: TPersistent); override;
        function IsThicknessStored: Boolean; virtual;
      public
        constructor Create;
        function Equals(AObject: TObject): Boolean; override;
      published
        property Color: TAlphaColor read FColor write SetColor default DefaultColor;
        property Decorations: TSkTextDecorations read FDecorations write SetDecorations default DefaultDecorations;
        property StrokeColor: TAlphaColor read FStrokeColor write SetStrokeColor default DefaultStrokeColor;
        property Style: TSkTextDecorationStyle read FStyle write SetStyle default DefaultStyle;
        property Thickness: Single read FThickness write SetThickness stored IsThicknessStored;
      end;
  strict protected
    const
      DefaultFontColor = TAlphaColors.Black;
      DefaultHeightMultiplier = 0;
      DefaultHorzAlign = TSkTextHorzAlign.Leading;
      DefaultLetterSpacing = 0;
      DefaultMaxLines = 1;
      DefaultTrimming = TSkTextTrimming.Word;
      DefaultVertAlign = TSkTextVertAlign.Center;
  strict private
    FDecorations: TDecorations;
    FFont: TSkFontComponent;
    FFontColor: TAlphaColor;
    FHeightMultiplier: Single;
    FHorzAlign: TSkTextHorzAlign;
    FLetterSpacing: Single;
    FMaxLines: NativeUInt;
    [unsafe] FOwner: TPersistent;
    FTrimming: TSkTextTrimming;
    FVertAlign: TSkTextVertAlign;
    procedure DecorationsChange(ASender: TObject);
    procedure FontChanged(ASender: TObject);
    function IsHeightMultiplierStored: Boolean;
    function IsLetterSpacingStored: Boolean;
    procedure SetDecorations(const AValue: TDecorations);
    procedure SetFont(const AValue: TSkFontComponent);
    procedure SetFontColor(const AValue: TAlphaColor);
    procedure SetHeightMultiplier(const AValue: Single);
    procedure SetHorzAlign(const AValue: TSkTextHorzAlign);
    procedure SetLetterSpacing(const AValue: Single);
    procedure SetMaxLines(const AValue: NativeUInt);
    procedure SetTrimming(const AValue: TSkTextTrimming);
    procedure SetVertAlign(const AValue: TSkTextVertAlign);
  strict protected
    procedure DoAssign(ASource: TPersistent); override;
    procedure DoAssignNotStyled(const ATextSettings: TSkTextSettings; const AStyledSettings: TSkStyledSettings); virtual;
  public
    constructor Create(const AOwner: TPersistent); virtual;
    destructor Destroy; override;
    procedure AssignNotStyled(const ATextSettings: TSkTextSettings; const AStyledSettings: TSkStyledSettings);
    function Equals(AObject: TObject): Boolean; override;
    procedure UpdateStyledSettings(const AOldTextSettings, ADefaultTextSettings: TSkTextSettings;
      var AStyledSettings: TSkStyledSettings); virtual;
    property Owner: TPersistent read FOwner;
  published
    property Decorations: TDecorations read FDecorations write SetDecorations;
    property Font: TSkFontComponent read FFont write SetFont;
    property FontColor: TAlphaColor read FFontColor write SetFontColor default DefaultFontColor;
    property HeightMultiplier: Single read FHeightMultiplier write SetHeightMultiplier stored IsHeightMultiplierStored;
    property HorzAlign: TSkTextHorzAlign read FHorzAlign write SetHorzAlign default DefaultHorzAlign;
    property LetterSpacing: Single read FLetterSpacing write SetLetterSpacing stored IsLetterSpacingStored;
    property MaxLines: NativeUInt read FMaxLines write SetMaxLines default DefaultMaxLines;
    property Trimming: TSkTextTrimming read FTrimming write SetTrimming default DefaultTrimming;
    property VertAlign: TSkTextVertAlign read FVertAlign write SetVertAlign default DefaultVertAlign;
  end;

  TSkTextSettingsClass = class of TSkTextSettings;

  { ISkTextSettings }

  ISkTextSettings = interface
    ['{CE7E837B-F927-4C78-B1D2-C62EF4A93014}']
    function GetDefaultTextSettings: TSkTextSettings;
    function GetResultingTextSettings: TSkTextSettings;
    function GetTextSettings: TSkTextSettings;
    procedure SetTextSettings(const AValue: TSkTextSettings);
    property DefaultTextSettings: TSkTextSettings read GetDefaultTextSettings;
    property ResultingTextSettings: TSkTextSettings read GetResultingTextSettings;
    property TextSettings: TSkTextSettings read GetTextSettings write SetTextSettings;
  end;

  { TSkTextSettingsInfo }

  TSkTextSettingsInfo = class(TPersistent)
  public
    type
      TBaseTextSettings = class(TSkTextSettings)
      strict private
        [unsafe] FControl: TControl;
        [unsafe] FInfo: TSkTextSettingsInfo;
      public
        constructor Create(const AOwner: TPersistent); override;
        property Control: TControl read FControl;
        property Info: TSkTextSettingsInfo read FInfo;
      end;

      TCustomTextSettings = class(TBaseTextSettings)
      public
        constructor Create(const AOwner: TPersistent); override;
      published
        property MaxLines default 0;
      end;

      TCustomTextSettingsClass = class of TCustomTextSettings;
  strict private
    FDefaultTextSettings: TSkTextSettings;
    FDesign: Boolean;
    FOldTextSettings: TSkTextSettings;
    FOnChange: TNotifyEvent;
    [unsafe] FOwner: TPersistent;
    FResultingTextSettings: TSkTextSettings;
    FStyledSettings: TSkStyledSettings;
    FTextSettings: TSkTextSettings;
    procedure OnCalculatedTextSettings(ASender: TObject);
    procedure OnDefaultChanged(ASender: TObject);
    procedure OnTextChanged(ASender: TObject);
    procedure SetDefaultTextSettings(const AValue: TSkTextSettings);
    procedure SetStyledSettings(const AValue: TSkStyledSettings);
    procedure SetTextSettings(const AValue: TSkTextSettings);
  strict protected
    procedure DoCalculatedTextSettings; virtual;
    procedure DoDefaultChanged; virtual;
    procedure DoStyledSettingsChanged; virtual;
    procedure DoTextChanged; virtual;
    procedure RecalculateTextSettings; virtual;
  public
    constructor Create(AOwner: TPersistent; ATextSettingsClass: TSkTextSettingsInfo.TCustomTextSettingsClass); virtual;
    destructor Destroy; override;
    property DefaultTextSettings: TSkTextSettings read FDefaultTextSettings write SetDefaultTextSettings;
    property Design: Boolean read FDesign write FDesign;
    property Owner: TPersistent read FOwner;
    property ResultingTextSettings: TSkTextSettings read FResultingTextSettings;
    property StyledSettings: TSkStyledSettings read FStyledSettings write SetStyledSettings;
    property TextSettings: TSkTextSettings read FTextSettings write SetTextSettings;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  { TSkLabel }

  TSkLabel = class(TSkCustomControl, ISkTextSettings)
  public
    type
      TWordsCollection = class;
      TCustomWordsItemClass = class of TCustomWordsItem;

      TCustomWordsItem = class(TCollectionItem)
      strict protected
        const
          DefaultBackgroundColor = TAlphaColors.Null;
          DefaultCaption = '';
          DefaultCursor = crDefault;
          DefaultFontColor = TAlphaColors.Black;
          DefaultHeightMultiplier = 0;
          DefaultLetterSpacing = 0;
          DefaultName = 'Item 0';
      strict private
        FBackgroundColor: TAlphaColor;
        FCaption: string;
        FChanged: Boolean;
        FCursor: TCursor;
        FIgnoringAllChanges: Boolean;
        FName: string;
        FOnClick: TNotifyEvent;
        FTag: NativeInt;
        FTagFloat: Single;
        [Weak] FTagObject: TObject;
        FTagString: string;
        FTextSettingsInfo: TSkTextSettingsInfo;
        FUpdatingCount: Integer;
        [unsafe] FWords: TWordsCollection;
        procedure CheckName(const AName: string; AWordsCollection: TWordsCollection);
        function GetDecorations: TSkTextSettings.TDecorations;
        function GetFont: TSkFontComponent;
        function GetFontColor: TAlphaColor;
        function GetHeightMultiplier: Single;
        function GetLetterSpacing: Single;
        function GetStyledSettings: TSkStyledSettings;
        function IsCaptionStored: Boolean;
        function IsFontColorStored: Boolean;
        function IsHeightMultiplierStored: Boolean;
        function IsLetterSpacingStored: Boolean;
        function IsNameStored: Boolean;
        function IsStyledSettingsStored: Boolean;
        procedure TextSettingsChange(ASender: TObject);
        procedure SetBackgroundColor(const AValue: TAlphaColor);
        procedure SetCaption(const AValue: string);
        procedure SetCursor(const AValue: TCursor);
        procedure SetDecorations(const AValue: TSkTextSettings.TDecorations);
        procedure SetFont(const AValue: TSkFontComponent);
        procedure SetFontColor(const AValue: TAlphaColor);
        procedure SetHeightMultiplier(const AValue: Single);
        procedure SetLetterSpacing(const AValue: Single);
        procedure SetName(const AValue: string);
        procedure SetStyledSettings(const AValue: TSkStyledSettings);
        function UniqueName(const AName: string; const ACollection: TCollection): string;
      strict protected
        procedure DoAssign(ASource: TPersistent); virtual;
        procedure DoChanged; virtual;
        function GetDisplayName: string; override;
        procedure SetCollection(AValue: TCollection); override;
      public
        constructor Create(ACollection: TCollection); override;
        destructor Destroy; override;
        procedure Assign(ASource: TPersistent); override; final;
        procedure BeginUpdate; overload;
        procedure Change; virtual;
        procedure EndUpdate; overload;
        procedure EndUpdate(const AIgnoreAllChanges: Boolean); overload; virtual;
        property BackgroundColor: TAlphaColor read FBackgroundColor write SetBackgroundColor default DefaultBackgroundColor;
        property Caption: string read FCaption write SetCaption stored IsCaptionStored;
        property Cursor: TCursor read FCursor write SetCursor default crDefault;
        property Decorations: TSkTextSettings.TDecorations read GetDecorations write SetDecorations;
        property Font: TSkFontComponent read GetFont write SetFont;
        property FontColor: TAlphaColor read GetFontColor write SetFontColor stored IsFontColorStored;
        property HeightMultiplier: Single read GetHeightMultiplier write SetHeightMultiplier stored IsHeightMultiplierStored;
        property LetterSpacing: Single read GetLetterSpacing write SetLetterSpacing stored IsLetterSpacingStored;
        /// <summary> The case-insensitive name of the item in the collection. This field cannot be empty and must be unique for his collection </summary>
        property Name: string read FName write SetName stored IsNameStored;
        property StyledSettings: TSkStyledSettings read GetStyledSettings write SetStyledSettings stored IsStyledSettingsStored;
        property Tag: NativeInt read FTag write FTag default 0;
        property TagFloat: Single read FTagFloat write FTagFloat;
        property TagObject: TObject read FTagObject write FTagObject;
        property TagString: string read FTagString write FTagString;
        property Words: TWordsCollection read FWords;
        property OnClick: TNotifyEvent read FOnClick write FOnClick;
      end;

      { TWordsCollection }

      TWordsCollection = class(TOwnedCollection)
      strict protected
        const
          DefaultColor = TAlphaColors.Black;
          DefaultFontSize = 14;
          DefaultFontSlant = TSkFontComponent.TSkFontSlant.Regular;
          DefaultFontWeight = TSkFontComponent.TSkFontWeight.Regular;
      strict private
        [unsafe] FLabel: TSkLabel;
        FOnChange: TNotifyEvent;
        function GetItem(AIndex: Integer): TCustomWordsItem;
        function GetItemByName(const AName: string): TCustomWordsItem;
        procedure SetItem(AIndex: Integer; const AValue: TCustomWordsItem);
      strict protected
        procedure Update(AItem: TCollectionItem); override;
      public
        constructor Create(AOwner: TPersistent; AItemClass: TCustomWordsItemClass);
        function Add: TCustomWordsItem; overload;
        function Add(const ACaption: string; const AColor: TAlphaColor = DefaultColor;
          const AFontSize: Single = DefaultFontSize;
          const AFontWeight: TSkFontComponent.TSkFontWeight = DefaultFontWeight;
          const AFontSlant: TSkFontComponent.TSkFontSlant = DefaultFontSlant): TCustomWordsItem; overload;
        function AddOrSet(const AName, ACaption: string; const AFontColor: TAlphaColor = DefaultColor;
          const AFont: TSkFontComponent = nil; const AOnClick: TNotifyEvent = nil;
          const ACursor: TCursor = crDefault): TCustomWordsItem;
        function Insert(AIndex: Integer): TCustomWordsItem;
        /// <summary> Case-insensitive search of item by name</summary>
        function IndexOf(const AName: string): Integer;
        /// <summary> Case-insensitive search of item by name</summary>
        property ItemByName[const AName: string]: TCustomWordsItem read GetItemByName;
        property Items[AIndex: Integer]: TCustomWordsItem read GetItem write SetItem; default;
        property &Label: TSkLabel read FLabel;
        property OnChange: TNotifyEvent read FOnChange write FOnChange;
      end;

      { TWordsItem }

      TWordsItem = class(TCustomWordsItem)
      published
        property BackgroundColor;
        property Caption;
        property Cursor;
        property Decorations;
        property Font;
        property FontColor;
        property HeightMultiplier;
        property LetterSpacing;
        property Name;
        property StyledSettings;
        property TagString;
        property OnClick;
      end;

      { TItemClickedMessage }

      TItemClickedMessage = class(TMessage<TCustomWordsItem>);
  strict private
    FBackgroundPicture: ISkPicture;
    FClickedPosition: TPoint;
    FHasCustomBackground: Boolean;
    FHasCustomCursor: Boolean;
    FIsMouseOver: Boolean;
    FParagraph: ISkParagraph;
    FParagraphBounds: TRectF;
    FParagraphLayoutWidth: Single;
    FParagraphStroked: ISkParagraph;
    FPressedPosition: TPoint;
    FTextSettingsInfo: TSkTextSettingsInfo;
    FWords: TWordsCollection;
    FWordsMouseOver: TCustomWordsItem;
    procedure CMBiDiModeChanged(var AMessage: TMessage); message CM_BIDIMODECHANGED;
    procedure CMControlChange(var AMessage: TMessage); message CM_CONTROLCHANGE;
    procedure CMMouseEnter(var AMessage: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var AMessage: TMessage); message CM_MOUSELEAVE;
    procedure CMParentBiDiModeChanged(var AMessage: TMessage); message CM_PARENTBIDIMODECHANGED;
    procedure DeleteParagraph;
    function GetCaption: string;
    procedure GetFitSize(var AWidth, AHeight: Single);
    function GetParagraph: ISkParagraph;
    function GetParagraphBounds: TRectF;
    function HasFitSizeChanged: Boolean;
    procedure ParagraphLayout(const AWidth: Single);
    procedure SetCaption(const AValue: string);
    procedure SetWords(const AValue: TWordsCollection);
    procedure SetWordsMouseOver(const AValue: TCustomWordsItem);
    procedure TextSettingsChanged(AValue: TObject);
    procedure WMLButtonUp(var AMessage: TWMLButtonUp); message WM_LBUTTONUP;
    procedure WMMouseMove(var AMessage: TWMMouseMove); message WM_MOUSEMOVE;
    procedure WordsChange(ASender: TObject);
  strict private
    { ISkTextSettings }
    function GetDefaultTextSettings: TSkTextSettings;
    function GetResultingTextSettings: TSkTextSettings;
    function GetTextSettings: TSkTextSettings;
    procedure SetTextSettings(const AValue: TSkTextSettings);
  strict protected
    function CanAutoSize(var ANewWidth, ANewHeight: Integer): Boolean; override;
    procedure Click; override;
    procedure Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single); override;
    function GetTextSettingsClass: TSkTextSettingsInfo.TCustomTextSettingsClass; virtual;
    function GetWordsItemAtPosition(const AX, AY: Integer): TCustomWordsItem;
    procedure Loaded; override;
    procedure MouseDown(AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer); override;
    procedure SetName(const AValue: TComponentName); override;
    property IsMouseOver: Boolean read FIsMouseOver;
    property Paragraph: ISkParagraph read GetParagraph;
    property ParagraphBounds: TRectF read GetParagraphBounds;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function UseRightToLeftAlignment: Boolean; override;
    property DefaultTextSettings: TSkTextSettings read GetDefaultTextSettings;
    property ResultingTextSettings: TSkTextSettings read GetResultingTextSettings;
  published
    property AutoSize default True;
    property BiDiMode;
    property Caption: string read GetCaption write SetCaption stored False;
    property ParentBiDiMode;
    property TextSettings: TSkTextSettings read GetTextSettings write SetTextSettings;
    property Words: TWordsCollection read FWords write SetWords;
  end;

  { TSkTypefaceManager }

  TSkTypefaceManager = class sealed
  strict private
    class var FProvider: ISkTypefaceFontProvider;
    class constructor Create;
  public
    class procedure RegisterTypeface(const AFileName: string); overload; static;
    class procedure RegisterTypeface(const AStream: TStream); overload; static;
    class property Provider: ISkTypefaceFontProvider read FProvider;
  end;

const
  AllStyledSettings: TSkStyledSettings = [TSkStyledSetting.Family, TSkStyledSetting.Size,
    TSkStyledSetting.Style, TSkStyledSetting.FontColor, TSkStyledSetting.Other];
  DefaultStyledSettings: TSkStyledSettings = [TSkStyledSetting.Family, TSkStyledSetting.Size,
    TSkStyledSetting.Style, TSkStyledSetting.FontColor];

procedure Register;

implementation

uses
  { Delphi }
  Winapi.MMSystem,
  System.Math.Vectors,
  System.ZLib,
  System.IOUtils,
  System.TypInfo,
  System.Character,
  System.Generics.Defaults,
  System.RTLConsts,
  Vcl.Forms;

type
  { TSkDefaultAnimationCodec }

  TSkDefaultAnimationCodec = class(TSkAnimatedImage.TAnimationCodec)
  strict private
    type
      TImageFormat = (GIF, WebP);
  strict private
    FAnimationCodec: ISkAnimationCodecPlayer;
    FStream: TStream;
  strict protected
    function GetDuration: Double; override;
    function GetFPS: Double; override;
    function GetIsStatic: Boolean; override;
    function GetSize: TSizeF; override;
  public
    constructor Create(const AAnimationCodec: ISkAnimationCodecPlayer; const AStream: TStream);
    destructor Destroy; override;
    procedure Render(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single); override;
    procedure SeekFrameTime(const ATime: Double); override;
    class function SupportedFormats: TArray<TSkAnimatedImage.TFormatInfo>; override;
    class function TryDetectFormat(const ABytes: TBytes; out AFormat: TSkAnimatedImage.TFormatInfo): Boolean; override;
    class function TryMakeFromStream(const AStream: TStream; out ACodec: TSkAnimatedImage.TAnimationCodec): Boolean; override;
  end;

  { TSkLottieAnimationCodec }

  TSkLottieAnimationCodec = class(TSkAnimatedImage.TAnimationCodec)
  strict private
    type
      TAnimationFormat = (Lottie, TGS);
  strict private
    FSkottie: ISkottieAnimation;
  strict protected
    function GetDuration: Double; override;
    function GetFPS: Double; override;
    function GetIsStatic: Boolean; override;
    function GetSize: TSizeF; override;
  public
    constructor Create(const ASkottie: ISkottieAnimation);
    procedure Render(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single); override;
    procedure SeekFrameTime(const ATime: Double); override;
    class function SupportedFormats: TArray<TSkAnimatedImage.TFormatInfo>; override;
    class function TryDetectFormat(const ABytes: TBytes; out AFormat: TSkAnimatedImage.TFormatInfo): Boolean; override;
    class function TryMakeFromStream(const AStream: TStream; out ACodec: TSkAnimatedImage.TAnimationCodec): Boolean; override;
  end;

  { TSkGraphic }

  TSkGraphic = class(TGraphic)
  strict private
    FBuffer: TBitmap;
    FBufferOpacity: Byte;
    FImage: ISkImage;
    function GetBuffer(const ASize: TSize; const AOpacity: Byte): TBitmap;
  strict protected
    procedure Changed(ASender: TObject); override;
    procedure Draw(ACanvas: TCanvas; const ARect: TRect); override;
    procedure DrawTransparent(ACanvas: TCanvas; const ARect: TRect; AOpacity: Byte); override;
    function Equals(AGraphic: TGraphic): Boolean; override;
    function GetEmpty: Boolean; override;
    function GetHeight: Integer; override;
    function GetSupportsPartialTransparency: Boolean; override;
    function GetWidth: Integer; override;
    procedure SetHeight(AValue: Integer); override;
    procedure SetWidth(AValue: Integer); override;
  public
    destructor Destroy; override;
    procedure Assign(ASource: TPersistent); override;
    {$IF CompilerVersion >= 32}
    class function CanLoadFromStream(AStream: TStream): Boolean; override;
    {$ENDIF}
    procedure LoadFromClipboardFormat(AFormat: Word; AData: THandle; APalette: HPALETTE); override;
    procedure LoadFromStream(AStream: TStream); override;
    procedure SaveToClipboardFormat(var AFormat: Word; var AData: THandle; var APalette: HPALETTE); override;
    procedure SaveToFile(const AFileName: string); override;
    procedure SaveToStream(AStream: TStream); override;
    procedure SetSize(AWidth, AHeight: Integer); override;
  end;

  { TSkSvgGraphic }

  TSkSvgGraphic = class(TGraphic)
  strict private
    FBuffer: TBitmap;
    FBufferOpacity: Byte;
    FSvgBrush: TSkSvgBrush;
    function GetBuffer(const ASize: TSize; const AOpacity: Byte): TBitmap;
  strict protected
    procedure Changed(ASender: TObject); override;
    procedure Draw(ACanvas: TCanvas; const ARect: TRect); override;
    procedure DrawTransparent(ACanvas: TCanvas; const ARect: TRect; AOpacity: Byte); override;
    function Equals(AGraphic: TGraphic): Boolean; override;
    function GetEmpty: Boolean; override;
    function GetHeight: Integer; override;
    function GetSupportsPartialTransparency: Boolean; override;
    function GetWidth: Integer; override;
    procedure SetHeight(AValue: Integer); override;
    procedure SetWidth(AValue: Integer); override;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure Assign(ASource: TPersistent); override;
    procedure LoadFromClipboardFormat(AFormat: Word; AData: THandle; APalette: HPALETTE); override;
    procedure LoadFromStream(AStream: TStream); override;
    procedure SaveToClipboardFormat(var AFormat: Word; var AData: THandle; var APalette: HPALETTE); override;
    procedure SaveToFile(const AFileName: string); override;
    procedure SaveToStream(AStream: TStream); override;
  end;

  {$IF CompilerVersion < 33}
  { TSkEpsilonHelper }

  TSkEpsilonHelper = record helper for TEpsilon
  const
    Scale = 1E-4;
    FontSize = 1E-2;
    Position = 1E-3;
  end;
  {$ENDIF}

  {$IF CompilerVersion < 32}
  { TSkRectFHelper }

  TSkRectFHelper = record helper for TRectF
  public
    function FitInto(const ADesignatedArea: TRectF): TRectF; overload;
    function FitInto(const ADesignatedArea: TRectF; out ARatio: Single): TRectF; overload;
  end;

  function RectCenter(var R: TRectF; const Bounds: TRectF): TRectF; forward;
  {$ENDIF}

function IsSameBytes(const ALeft, ARight: TBytes): Boolean;
begin
  Result := (ALeft = ARight) or
    ((Length(ALeft) = Length(ARight)) and
    ((Length(ALeft) = 0) or CompareMem(PByte(@ALeft[0]), PByte(@ARight[0]), Length(ALeft))));
end;

function PlaceIntoTopLeft(const ASourceRect, ADesignatedArea: TRectF): TRectF;
begin
  Result := ASourceRect;
  if (ASourceRect.Width > ADesignatedArea.Width) or (ASourceRect.Height > ADesignatedArea.Height) then
    Result := Result.FitInto(ADesignatedArea);
  Result.SetLocation(ADesignatedArea.TopLeft);
end;

{$IF CompilerVersion < 32}
{ TSkRectFHelper }

function TSkRectFHelper.FitInto(const ADesignatedArea: TRectF): TRectF;
var
  LRatio: Single;
begin
  Result := FitInto(ADesignatedArea, LRatio);
end;

function TSkRectFHelper.FitInto(const ADesignatedArea: TRectF; out ARatio: Single): TRectF;
begin
  if (ADesignatedArea.Width <= 0) or (ADesignatedArea.Height <= 0) then
  begin
    ARatio := 1;
    Exit(Self);
  end;

  if (Self.Width / ADesignatedArea.Width) > (Self.Height / ADesignatedArea.Height) then
    ARatio := Self.Width / ADesignatedArea.Width
  else
    ARatio := Self.Height / ADesignatedArea.Height;

  if ARatio = 0 then
    Exit(Self)
  else
  begin
    Result := TRectF.Create(0, 0, Self.Width / ARatio, Self.Height / ARatio);
    RectCenter(Result, ADesignatedArea);
  end;
end;

function RectCenter(var R: TRectF; const Bounds: TRectF): TRectF;
begin
  OffsetRect(R, -R.Left, -R.Top);
  OffsetRect(R, (RectWidth(Bounds)/2 - RectWidth(R)/2), (RectHeight(Bounds)/2 - RectHeight(R)/2));
  OffsetRect(R, Bounds.Left, Bounds.Top);
  Result := R;
end;
{$ENDIF}

{ TSkBitmapHelper }

procedure TSkBitmapHelper.FlipPixels(const AWidth, AHeight: Integer;
  const ASrcPixels: PByte; const ASrcStride: Integer; const ADestPixels: PByte;
  const ADestStride: Integer);
var
  I: Integer;
begin
  for I := 0 to AHeight - 1 do
    Move(ASrcPixels[I * ASrcStride], ADestPixels[(AHeight - I - 1) * ADestStride], AWidth * 4);
end;

procedure TSkBitmapHelper.SkiaDraw(const AProc: TSkDrawProc; const AStartClean: Boolean);
var
  LPixmap: ISkPixmap;
  LSurface: ISkSurface;
begin
  Assert(Assigned(AProc));
  if Empty then
    raise ESkBitmapHelper.Create('Invalid bitmap');
  if not SupportsPartialTransparency then
  begin
    PixelFormat := TPixelFormat.pf32bit;
    AlphaFormat := TAlphaFormat.afPremultiplied;
  end;
  LSurface := TSkSurface.MakeRaster(Width, Height);
  LPixmap  := LSurface.PeekPixels;
  if AStartClean then
    LSurface.Canvas.Clear(TAlphaColors.Null)
  else
    FlipPixels(Width, Height, ScanLine[Height - 1], BytesPerScanLine(Width, 32, 32), LPixmap.Pixels, LPixmap.RowBytes);
  AProc(LSurface.Canvas);
  FlipPixels(Width, Height, LPixmap.Pixels, LPixmap.RowBytes, ScanLine[Height - 1], BytesPerScanLine(Width, 32, 32));
end;

function TSkBitmapHelper.ToSkImage: ISkImage;
var
  LPixels: Pointer;
  LStride: Integer;
begin
  if Empty then
    raise ESkBitmapHelper.Create('Invalid bitmap');
  if not SupportsPartialTransparency then
  begin
    PixelFormat := TPixelFormat.pf32bit;
    AlphaFormat := TAlphaFormat.afPremultiplied;
  end;
  LStride := BytesPerScanLine(Width, 32, 32);
  GetMem(LPixels, LStride * Height);
  try
    FlipPixels(Width, Height, ScanLine[Height - 1], BytesPerScanLine(Width, 32, 32), LPixels, LStride);
    Result := TSkImage.MakeFromRaster(TSkImageInfo.Create(Width, Height), LPixels, LStride);
  finally
    FreeMem(LPixels);
  end;
end;

{ TSkCustomControl }

{$IF CompilerVersion < 33}
procedure TSkCustomControl.ChangeScale(M, D: Integer);
begin
  if M <> D then
    FScaleFactor := FScaleFactor * M / D;
  inherited;
end;
{$ENDIF}

constructor TSkCustomControl.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csReplicatable] - [csOpaque];
  FDrawCacheKind := TSkDrawCacheKind.Raster;
  FOpacity := 255;
  {$IF CompilerVersion < 33}
  FScaleFactor := 1;
  {$ENDIF}
  Height := 50;
  Width := 50;
end;

procedure TSkCustomControl.CreateBuffer(const AMemDC: HDC; out ABuffer: HBITMAP;
  out AData: Pointer; out AStride: Integer);
const
  ColorMasks: array[0..2] of DWORD = ($00FF0000, $0000FF00, $000000FF);
var
  LBitmapInfo: PBitmapInfo;
begin
  AStride := BytesPerScanline(Width, 32, 32);
  GetMem(LBitmapInfo, SizeOf(TBitmapInfoHeader) + SizeOf(ColorMasks));
  try
    LBitmapInfo.bmiHeader := Default(TBitmapInfoHeader);
    LBitmapInfo.bmiHeader.biSize        := SizeOf(TBitmapInfoHeader);
    LBitmapInfo.bmiHeader.biWidth       := Width;
    LBitmapInfo.bmiHeader.biHeight      := -Height;
    LBitmapInfo.bmiHeader.biPlanes      := 1;
    LBitmapInfo.bmiHeader.biBitCount    := 32;
    LBitmapInfo.bmiHeader.biCompression := BI_BITFIELDS;
    LBitmapInfo.bmiHeader.biSizeImage   := AStride * Height;
    Move(ColorMasks[0], LBitmapInfo.bmiColors[0], SizeOf(ColorMasks));
    ABuffer := CreateDIBSection(AMemDC, LBitmapInfo^, DIB_RGB_COLORS, AData, 0, 0);
    if ABuffer <> 0 then
      GdiFlush;
  finally
    FreeMem(LBitmapInfo);
  end;
end;

procedure TSkCustomControl.DeleteBuffers;
begin
  if FDrawBuffer <> 0 then
  begin
    FDrawCached := False;
    DeleteObject(FDrawBuffer);
    FDrawBuffer := 0;
  end;
end;

destructor TSkCustomControl.Destroy;
begin
  DeleteBuffers;
  inherited;
end;

procedure TSkCustomControl.Draw(const ACanvas: ISkCanvas; const ADest: TRectF;
  const AOpacity: Single);
begin
  if csDesigning in ComponentState then
    DrawDesignBorder(ACanvas, ADest, AOpacity);
end;

procedure TSkCustomControl.DrawDesignBorder(const ACanvas: ISkCanvas;
  const ADest: TRectF; const AOpacity: Single);
const
  DesignBorderColor = $A0909090;
var
  R: TRectF;
  LPaint: ISkPaint;
begin
  R := ADest;
  InflateRect(R, -0.5, -0.5);
  ACanvas.Save;
  try
    LPaint := TSkPaint.Create(TSkPaintStyle.Stroke);
    LPaint.AlphaF := AOpacity;
    LPaint.Color := DesignBorderColor;
    LPaint.StrokeWidth := 1;
    LPaint.PathEffect := TSKPathEffect.MakeDash([3, 1], 0);
    ACanvas.DrawRect(R, LPaint);
  finally
    ACanvas.Restore;
  end;
end;

function TSkCustomControl.NeedsRedraw: Boolean;
begin
  Result := (not FDrawCached) or (FDrawCacheKind = TSkDrawCacheKind.Never) or (FDrawBuffer = 0);
end;

procedure TSkCustomControl.Paint;

  procedure InternalDraw;
  var
    LSurface: ISkSurface;
    LDestRect: TRectF;
  begin
    LSurface := TSkSurface.MakeRasterDirect(TSkImageInfo.Create(Width, Height), FDrawBufferData, FDrawBufferStride);
    LSurface.Canvas.Clear(TAlphaColors.Null);
    LSurface.Canvas.Concat(TMatrix.CreateScaling(ScaleFactor, ScaleFactor));
    LDestRect := RectF(0, 0, Width / ScaleFactor, Height / ScaleFactor);
    Draw(LSurface.Canvas, LDestRect, 1);
    if Assigned(FOnDraw) then
      FOnDraw(Self, LSurface.Canvas, LDestRect, 1);
    FDrawCached := True;
  end;

const
  BlendFunction: TBlendFunction = (BlendOp: AC_SRC_OVER; BlendFlags: 0; SourceConstantAlpha: 255; AlphaFormat: AC_SRC_ALPHA);
var
  LOldObj: HGDIOBJ;
  LDrawBufferDC: HDC;
  LBlendFunction: TBlendFunction;
begin
  if (Width <= 0) or (Height <= 0) then
    Exit;

  LDrawBufferDC := CreateCompatibleDC(0);
  if LDrawBufferDC <> 0 then
    try
      if FDrawBuffer = 0 then
        CreateBuffer(LDrawBufferDC, FDrawBuffer, FDrawBufferData, FDrawBufferStride);
      if FDrawBuffer <> 0 then
      begin
        LOldObj := SelectObject(LDrawBufferDC, FDrawBuffer);
        try
          if NeedsRedraw then
            InternalDraw;
          LBlendFunction := BlendFunction;
          LBlendFunction.SourceConstantAlpha := FOpacity;
          AlphaBlend(Canvas.Handle, 0, 0, Width, Height, LDrawBufferDC, 0, 0, Width, Height, LBlendFunction);
        finally
          if LOldObj <> 0 then
            SelectObject(LDrawBufferDC, LOldObj);
        end;
      end;
    finally
      DeleteDC(LDrawBufferDC);
    end;
end;

procedure TSkCustomControl.Redraw;
begin
  FDrawCached := False;
  Repaint;
end;

procedure TSkCustomControl.Resize;
begin
  DeleteBuffers;
  inherited;
end;

procedure TSkCustomControl.SetDrawCacheKind(const AValue: TSkDrawCacheKind);
begin
  if FDrawCacheKind <> AValue then
  begin
    FDrawCacheKind := AValue;
    if FDrawCacheKind <> TSkDrawCacheKind.Always then
      Repaint;
  end;
end;

procedure TSkCustomControl.SetOnDraw(const AValue: TSkDrawEvent);
begin
  if TMethod(FOnDraw) <> TMethod(AValue) then
  begin
    FOnDraw := AValue;
    Redraw;
  end;
end;

procedure TSkCustomControl.SetOpacity(const AValue: Byte);
begin
  if FOpacity <> AValue then
  begin
    FOpacity := AValue;
    Repaint;
  end;
end;

{ TSkSvgBrush }

procedure TSkSvgBrush.Assign(ASource: TPersistent);
var
  LSourceSvgBrush: TSkSvgBrush absolute ASource;
begin
  if ASource is TSkSvgBrush then
  begin
    if not Equals(LSourceSvgBrush) then
    begin
      DoAssign(LSourceSvgBrush);
      DoChanged;
    end;
  end
  else
    inherited;
end;

constructor TSkSvgBrush.Create;
begin
  inherited Create;
  FGrayScale := DefaultGrayScale;
  FWrapMode := DefaultWrapMode;
end;

procedure TSkSvgBrush.DoAssign(ASource: TSkSvgBrush);
begin
  FDOM := ASource.FDOM;
  FGrayScale := ASource.FGrayScale;
  FOriginalSize := ASource.FOriginalSize;
  FOverrideColor := ASource.FOverrideColor;
  FSource := ASource.FSource;
  FWrapMode := ASource.FWrapMode;
end;

procedure TSkSvgBrush.DoChanged;
begin
  if Assigned(FOnChanged) then
    FOnChanged(Self);
end;

function TSkSvgBrush.Equals(AObject: TObject): Boolean;
var
  LObjectSvgBrush: TSkSvgBrush absolute AObject;
begin
  Result := (AObject is TSkSvgBrush) and
    (FGrayScale = LObjectSvgBrush.FGrayScale) and
    (FOverrideColor = LObjectSvgBrush.FOverrideColor) and
    (FWrapMode = LObjectSvgBrush.FWrapMode) and
    (FSource = LObjectSvgBrush.FSource);
end;

function TSkSvgBrush.GetDOM: ISkSVGDOM;
var
  LSvgRect: TRectF;
begin
  if (FDOM = nil) and HasContent then
  begin
    FDOM := MakeDOM;
    if Assigned(FDOM) then
    begin
      LSvgRect.TopLeft := PointF(0, 0);
      LSvgRect.Size := FDOM.Root.GetIntrinsicSize(TSizeF.Create(0, 0));
      if (not LSvgRect.IsEmpty) or (FDOM.Root.TryGetViewBox(LSvgRect) and not LSvgRect.IsEmpty) then
        FOriginalSize := LSvgRect.Size;
    end;
  end;
  Result := FDOM;
end;

function TSkSvgBrush.GetOriginalSize: TSizeF;
begin
  if (FDOM = nil) and HasContent then
    GetDOM;
  Result := FOriginalSize;
end;

function TSkSvgBrush.HasContent: Boolean;
begin
  Result := FSource <> '';
end;

function TSkSvgBrush.IsGrayScaleStored: Boolean;
begin
  Result := FGrayScale <> DefaultGrayScale;
end;

function TSkSvgBrush.IsOverrideColorStored: Boolean;
begin
  Result := FOverrideColor <> Default(TAlphaColor);
end;

function TSkSvgBrush.IsWrapModeStored: Boolean;
begin
  Result := FWrapMode <> DefaultWrapMode;
end;

function TSkSvgBrush.MakeDOM: ISkSVGDOM;
begin
  Result := TSkSVGDOM.Make(FSource);
end;

procedure TSkSvgBrush.RecreateDOM;
begin
  FDOM := nil;
  FOriginalSize := TSizeF.Create(0, 0);
end;

procedure TSkSvgBrush.Render(const ACanvas: ISkCanvas; const ADestRect: TRectF;
  const AOpacity: Single);

  function GetWrappedDest(const ADOM: ISkSVGDOM; const ASvgRect, ADestRect: TRectF; const AIntrinsicSize: TSizeF): TRectF;
  var
    LRatio: Single;
  begin
    case FWrapMode of
      TSkSvgWrapMode.Default:
        begin
          if AIntrinsicSize.IsZero then
            Result := ADestRect
          else
          begin
            Result := ASvgRect;
            Result.Offset(ADestRect.TopLeft);
          end;
          ADOM.SetContainerSize(ADestRect.Size);
        end;
      TSkSvgWrapMode.Fit: Result := ASvgRect.FitInto(ADestRect);
      TSkSvgWrapMode.FitCrop:
        begin
          if (ASvgRect.Width / ADestRect.Width) < (ASvgRect.Height / ADestRect.Height) then
            LRatio := ASvgRect.Width / ADestRect.Width
          else
            LRatio := ASvgRect.Height / ADestRect.Height;
          if SameValue(LRatio, 0, TEpsilon.Vector) then
            Result := ADestRect
          else
          begin
            Result := RectF(0, 0, Round(ASvgRect.Width / LRatio), Round(ASvgRect.Height / LRatio));
            RectCenter(Result, ADestRect);
          end;
        end;
      TSkSvgWrapMode.Original,
      TSkSvgWrapMode.Tile: Result := ASvgRect;
      TSkSvgWrapMode.OriginalCenter:
        begin
          Result := ASvgRect;
          RectCenter(Result, ADestRect);
        end;
      TSkSvgWrapMode.Place: Result := PlaceIntoTopLeft(ASvgRect, ADestRect);
      TSkSvgWrapMode.Stretch: Result := ADestRect;
    else
      Result := ADestRect;
    end;
  end;

  procedure DrawTileOrCustomColor(const ACanvas: ISkCanvas; const ADOM: ISkSVGDOM;
    const ASvgRect, ADestRect, AWrappedDest: TRectF; const AIntrinsicSize: TSizeF;
    const AWrapMode: TSkSvgWrapMode);
  var
    LPicture: ISkPicture;
    LPictureRecorder: ISkPictureRecorder;
    LCanvas: ISkCanvas;
    LPaint: ISkPaint;
  begin
    LPictureRecorder := TSkPictureRecorder.Create;
    LCanvas := LPictureRecorder.BeginRecording(AWrappedDest.Width, AWrappedDest.Height);
    if AIntrinsicSize.IsZero then
    begin
      if AWrapMode <> TSkSvgWrapMode.Default then
      begin
        ADOM.Root.Width  := TSkSVGLength.Create(AWrappedDest.Width,  TSkSVGLengthUnit.PX);
        ADOM.Root.Height := TSkSVGLength.Create(AWrappedDest.Height, TSkSVGLengthUnit.PX);
      end;
    end
    else
      LCanvas.Scale(AWrappedDest.Width / ASvgRect.Width, AWrappedDest.Height / ASvgRect.Height);
    ADOM.Render(LCanvas);
    LPicture := LPictureRecorder.FinishRecording;
    LPaint := TSkPaint.Create;
    if FGrayScale then
      LPaint.ColorFilter := TSkColorFilter.MakeMatrix(TSkColorMatrix.CreateSaturation(0))
    else if FOverrideColor <> TAlphaColors.Null then
      LPaint.ColorFilter := TSkColorFilter.MakeBlend(FOverrideColor, TSkBlendMode.SrcIn);
    if FWrapMode = TSkSvgWrapMode.Tile then
    begin
      LPaint.Shader := LPicture.MakeShader(TSkTileMode.Repeat, TSkTileMode.Repeat);
      ACanvas.DrawRect(ADestRect, LPaint);
    end
    else
    begin
      ACanvas.Translate(AWrappedDest.Left, AWrappedDest.Top);
      ACanvas.DrawPicture(LPicture, LPaint);
    end;
  end;

var
  LDOM: ISkSVGDOM;
  LSvgRect: TRectF;
  LWrappedDest: TRectF;
  LIntrinsicSize: TSizeF;
begin
  if not ADestRect.IsEmpty then
  begin
    LDOM := DOM;
    if Assigned(LDOM) then
    begin
      LSvgRect.TopLeft := PointF(0, 0);
      LIntrinsicSize := LDOM.Root.GetIntrinsicSize(TSizeF.Create(0, 0));
      LSvgRect.Size := LIntrinsicSize;
      if LSvgRect.IsEmpty and ((not LDOM.Root.TryGetViewBox(LSvgRect)) or LSvgRect.IsEmpty) then
        Exit;

      if SameValue(AOpacity, 1, TEpsilon.Position) then
        ACanvas.Save
      else
        ACanvas.SaveLayerAlpha(Round(AOpacity * 255));
      try
        LWrappedDest := GetWrappedDest(LDOM, LSvgRect, ADestRect, LIntrinsicSize);
        if (FOverrideColor <> TAlphaColors.Null) or (FWrapMode = TSkSvgWrapMode.Tile) or FGrayScale then
          DrawTileOrCustomColor(ACanvas, LDOM, LSvgRect, ADestRect, LWrappedDest, LIntrinsicSize, FWrapMode)
        else
        begin
          ACanvas.Translate(LWrappedDest.Left, LWrappedDest.Top);
          if LIntrinsicSize.IsZero then
          begin
            if FWrapMode <> TSkSvgWrapMode.Default then
            begin
              LDOM.Root.Width  := TSkSVGLength.Create(LWrappedDest.Width,  TSkSVGLengthUnit.PX);
              LDOM.Root.Height := TSkSVGLength.Create(LWrappedDest.Height, TSkSVGLengthUnit.PX);
            end;
          end
          else
            ACanvas.Scale(LWrappedDest.Width / LSvgRect.Width, LWrappedDest.Height / LSvgRect.Height);
          LDOM.Render(ACanvas);
        end;
      finally
        ACanvas.Restore;
      end;
    end;
  end;
end;

procedure TSkSvgBrush.SetGrayScale(const AValue: Boolean);
begin
  if FGrayScale <> AValue then
  begin
    FGrayScale := AValue;
    if HasContent then
      DoChanged;
  end;
end;

procedure TSkSvgBrush.SetOverrideColor(const AValue: TAlphaColor);
begin
  if FOverrideColor <> AValue then
  begin
    FOverrideColor := AValue;
    if HasContent then
      DoChanged;
  end;
end;

procedure TSkSvgBrush.SetSource(const AValue: TSkSvgSource);
begin
  if FSource <> AValue then
  begin
    FSource := AValue;
    RecreateDOM;
    DoChanged;
  end;
end;

procedure TSkSvgBrush.SetWrapMode(const AValue: TSkSvgWrapMode);
begin
  if FWrapMode <> AValue then
  begin
    FWrapMode := AValue;
    RecreateDOM;
    if HasContent then
      DoChanged;
  end;
end;

{ TSkSvg }

constructor TSkSvg.Create(AOwner: TComponent);
begin
  inherited;
  FSvg := CreateSvgBrush;
  FSvg.OnChanged := SvgChanged;
  DrawCacheKind := TSkDrawCacheKind.Always;
end;

function TSkSvg.CreateSvgBrush: TSkSvgBrush;
begin
  Result := TSkSvgBrush.Create;
end;

destructor TSkSvg.Destroy;
begin
  FSvg.Free;
  inherited;
end;

procedure TSkSvg.Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
begin
  inherited;
  FSvg.Render(ACanvas, ADest, AOpacity);
end;

procedure TSkSvg.SetSvg(const AValue: TSkSvgBrush);
begin
  FSvg.Assign(AValue);
end;

procedure TSkSvg.SvgChanged(ASender: TObject);
begin
  Redraw;
end;

type
  TWinControlAccess = class(TWinControl);

{ TSkCustomWinControl }

{$IF CompilerVersion < 33}
procedure TSkCustomWinControl.ChangeScale(M, D: Integer);
begin
  if M <> D then
    FScaleFactor := FScaleFactor * M / D;
  inherited;
end;
{$ENDIF}

constructor TSkCustomWinControl.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle - [csOpaque];
  FDrawCacheKind := TSkDrawCacheKind.Raster;
  FOpacity := 255;
  {$IF CompilerVersion < 33}
  FScaleFactor := 1;
  {$ENDIF}
  Height := 50;
  Width := 50;
end;

procedure TSkCustomWinControl.CreateBuffer(const AMemDC: HDC; out ABuffer: HBITMAP;
  out AData: Pointer; out AStride: Integer);
const
  ColorMasks: array[0..2] of DWORD = ($00FF0000, $0000FF00, $000000FF);
var
  LBitmapInfo: PBitmapInfo;
begin
  AStride := BytesPerScanline(Width, 32, 32);
  GetMem(LBitmapInfo, SizeOf(TBitmapInfoHeader) + SizeOf(ColorMasks));
  try
    LBitmapInfo.bmiHeader := Default(TBitmapInfoHeader);
    LBitmapInfo.bmiHeader.biSize        := SizeOf(TBitmapInfoHeader);
    LBitmapInfo.bmiHeader.biWidth       := Width;
    LBitmapInfo.bmiHeader.biHeight      := -Height;
    LBitmapInfo.bmiHeader.biPlanes      := 1;
    LBitmapInfo.bmiHeader.biBitCount    := 32;
    LBitmapInfo.bmiHeader.biCompression := BI_BITFIELDS;
    LBitmapInfo.bmiHeader.biSizeImage   := AStride * Height;
    Move(ColorMasks[0], LBitmapInfo.bmiColors[0], SizeOf(ColorMasks));
    ABuffer := CreateDIBSection(AMemDC, LBitmapInfo^, DIB_RGB_COLORS, AData, 0, 0);
    if ABuffer <> 0 then
      GdiFlush;
  finally
    FreeMem(LBitmapInfo);
  end;
end;

procedure TSkCustomWinControl.DeleteBuffers;
begin
  FDrawCached := False;
  if FDrawBuffer <> 0 then
  begin
    DeleteObject(FDrawBuffer);
    FDrawBuffer := 0;
  end;
  FreeAndNil(FBackgroundBuffer);
end;

destructor TSkCustomWinControl.Destroy;
begin
  DeleteBuffers;
  inherited;
end;

procedure TSkCustomWinControl.Draw(const ACanvas: ISkCanvas; const ADest: TRectF;
  const AOpacity: Single);
begin
  if csDesigning in ComponentState then
    DrawDesignBorder(ACanvas, ADest, AOpacity);
end;

procedure TSkCustomWinControl.DrawDesignBorder(const ACanvas: ISkCanvas;
  const ADest: TRectF; const AOpacity: Single);
const
  DesignBorderColor = $A0909090;
var
  R: TRectF;
  LPaint: ISkPaint;
begin
  R := ADest;
  InflateRect(R, -0.5, -0.5);
  ACanvas.Save;
  try
    LPaint := TSkPaint.Create(TSkPaintStyle.Stroke);
    LPaint.AlphaF := AOpacity;
    LPaint.Color := DesignBorderColor;
    LPaint.StrokeWidth := 1;
    LPaint.PathEffect := TSKPathEffect.MakeDash([3, 1], 0);
    ACanvas.DrawRect(R, LPaint);
  finally
    ACanvas.Restore;
  end;
end;

procedure TSkCustomWinControl.DrawParentImage(ADC: HDC;
  AInvalidateParent: Boolean);

  function LocalToParent(const AParent: TWinControl): TPoint;
  var
    LControl: TWinControl;
  begin
    Result := Point(0, 0);
    LControl := Self;
    repeat
      Result := Result + LControl.BoundsRect.TopLeft;
      LControl := LControl.Parent;
    until (LControl = AParent);
  end;

var
  LSaveIndex: Integer;
  LPoint: TPoint;
  LParentOffset: TPoint;
  LOpaqueParent: TWinControl;
begin
  LOpaqueParent := GetOpaqueParent;
  if LOpaqueParent = nil then
    Exit;
  LSaveIndex := SaveDC(ADC);
  GetViewportOrgEx(ADC, LPoint);
  LParentOffset := LocalToParent(LOpaqueParent);
  SetViewportOrgEx(ADC, LPoint.X - LParentOffset.X, LPoint.Y - LParentOffset.Y, nil);
  IntersectClipRect(ADC, 0, 0, LOpaqueParent.ClientWidth, LOpaqueParent.ClientHeight);
  LOpaqueParent.Perform(WM_ERASEBKGND, ADC, 0);
  LOpaqueParent.Perform(WM_PRINTCLIENT, ADC, prf_Client);
  RestoreDC(ADC, LSaveIndex);
  if AInvalidateParent and not (LOpaqueParent is TCustomControl) and
    not (LOpaqueParent is TCustomForm) and not (csDesigning in ComponentState) then
  begin
    LOpaqueParent.Invalidate;
  end;
end;

function TSkCustomWinControl.GetOpaqueParent: TWinControl;
begin
  if Parent = nil then
    Exit(nil);
  Result := Self;
  while Result.Parent <> nil do
  begin
    Result := Result.Parent;
    if not TWinControlAccess(Result).ParentBackground then
      Break;
  end;
end;

function TSkCustomWinControl.NeedsRedraw: Boolean;
begin
  Result := (not FDrawCached) or (FDrawCacheKind = TSkDrawCacheKind.Never) or (FDrawBuffer = 0);
end;

procedure TSkCustomWinControl.Paint;

  procedure InternalDraw;
  var
    LSurface: ISkSurface;
    LDestRect: TRectF;
  begin
    LSurface := TSkSurface.MakeRasterDirect(TSkImageInfo.Create(Width, Height), FDrawBufferData, FDrawBufferStride);
    LSurface.Canvas.Clear(TAlphaColors.Null);
    LSurface.Canvas.Concat(TMatrix.CreateScaling(ScaleFactor, ScaleFactor));
    LDestRect := RectF(0, 0, Width / ScaleFactor, Height / ScaleFactor);
    Draw(LSurface.Canvas, LDestRect, 1);
    if Assigned(FOnDraw) then
      FOnDraw(Self, LSurface.Canvas, LDestRect, 1);
    FDrawCached := True;
  end;

const
  BlendFunction: TBlendFunction = (BlendOp: AC_SRC_OVER; BlendFlags: 0; SourceConstantAlpha: 255; AlphaFormat: AC_SRC_ALPHA);
var
  LOldObj: HGDIOBJ;
  LDrawBufferDC: HDC;
  LBlendFunction: TBlendFunction;
begin
  if (Width <= 0) or (Height <= 0) then
    Exit;

  LDrawBufferDC := CreateCompatibleDC(0);
  if LDrawBufferDC <> 0 then
    try
      if FDrawParentInBackground then
      begin
        if FBackgroundBuffer = nil then
        begin
          FBackgroundBuffer := TBitmap.Create;
          FBackgroundBuffer.SetSize(Width, Height);
        end;
        if (Parent <> nil) and Parent.DoubleBuffered then
          PerformEraseBackground(Self, FBackgroundBuffer.Canvas.Handle);
        DrawParentImage(FBackgroundBuffer.Canvas.Handle);
      end;

      if FDrawBuffer = 0 then
        CreateBuffer(LDrawBufferDC, FDrawBuffer, FDrawBufferData, FDrawBufferStride);
      if FDrawBuffer <> 0 then
      begin
        LOldObj := SelectObject(LDrawBufferDC, FDrawBuffer);
        try
          if NeedsRedraw then
            InternalDraw;
          LBlendFunction := BlendFunction;
          LBlendFunction.SourceConstantAlpha := FOpacity;
          if FDrawParentInBackground then
            AlphaBlend(FBackgroundBuffer.Canvas.Handle, 0, 0, Width, Height, LDrawBufferDC, 0, 0, Width, Height, LBlendFunction)
          else
            AlphaBlend(Canvas.Handle, 0, 0, Width, Height, LDrawBufferDC, 0, 0, Width, Height, LBlendFunction);
        finally
          if LOldObj <> 0 then
            SelectObject(LDrawBufferDC, LOldObj);
        end;
      end;

      if FDrawParentInBackground then
        Canvas.Draw(0, 0, FBackgroundBuffer);
    finally
      DeleteDC(LDrawBufferDC);
    end;
end;

procedure TSkCustomWinControl.Redraw;
begin
  FDrawCached := False;
  Repaint;
end;

procedure TSkCustomWinControl.Resize;
begin
  DeleteBuffers;
  inherited;
end;

procedure TSkCustomWinControl.SetDrawCacheKind(const AValue: TSkDrawCacheKind);
begin
  if FDrawCacheKind <> AValue then
  begin
    FDrawCacheKind := AValue;
    if FDrawCacheKind <> TSkDrawCacheKind.Always then
      Repaint;
  end;
end;

procedure TSkCustomWinControl.SetDrawParentInBackground(const AValue: Boolean);
begin
  if FDrawParentInBackground <> AValue then
  begin
    FDrawParentInBackground := AValue;
    Repaint;
  end;
end;

procedure TSkCustomWinControl.SetOnDraw(const AValue: TSkDrawEvent);
begin
  if TMethod(FOnDraw) <> TMethod(AValue) then
  begin
    FOnDraw := AValue;
    Redraw;
  end;
end;

procedure TSkCustomWinControl.SetOpacity(const AValue: Byte);
begin
  if FOpacity <> AValue then
  begin
    FOpacity := AValue;
    Repaint;
  end;
end;

procedure TSkCustomWinControl.WMEraseBkgnd(var AMessage: TWMEraseBkgnd);
var
  LOpaqueParent: TWinControl;
begin
  if FDrawParentInBackground then
  begin
    LOpaqueParent := GetOpaqueParent;
    if (LOpaqueParent <> nil) and LOpaqueParent.DoubleBuffered then
      PerformEraseBackground(Self, AMessage.DC);
    DrawParentImage(AMessage.DC, True);
    AMessage.Result := 1;
  end
  else
    inherited;
end;

{ TSkCustomAnimation.TProcess }

class procedure TSkCustomAnimation.TProcess.Add(const AAnimation: TSkCustomAnimation);
begin
  if FProcess = nil then
    FProcess := TProcess.Create;
  FProcess.DoAdd(AAnimation);
end;

constructor TSkCustomAnimation.TProcess.Create;
begin
  inherited Create;
  FAniList := TList<Pointer>.Create;
  FAniProcessingList := TList<Pointer>.Create;
  FrameRate := EnsureRange(FrameRate, 5, 120);
  FAnimation := TTimer.Create(nil);
  FAnimation.Enabled := False;
  FAnimation.Interval := Trunc(1000 / FrameRate);
  FAnimation.OnTimer := OnProcess;
  if not QueryPerformanceFrequency(FPerformanceFrequency) then
    FPerformanceFrequency := 0;
end;

destructor TSkCustomAnimation.TProcess.Destroy;
begin
  FreeAndNil(FAniList);
  FAniProcessingList.Free;
  FAnimation.Free;
  inherited;
end;

class destructor TSkCustomAnimation.TProcess.Destroy;
begin
  FProcess.Free;
  inherited;
end;

procedure TSkCustomAnimation.TProcess.DoAdd(const AAnimation: TSkCustomAnimation);
begin
  if FAniList.IndexOf(AAnimation) < 0 then
    FAniList.Add(AAnimation);
  if not FAnimation.Enabled and (FAniList.Count > 0) then
    FTime := GetTick;
  FAnimation.Enabled := FAniList.Count > 0;
end;

procedure TSkCustomAnimation.TProcess.DoRemove(const AAnimation: TSkCustomAnimation);
begin
  if FAniList <> nil then
  begin
    FAniList.Remove(AAnimation);
    FAniProcessingList.Remove(AAnimation);
    FAnimation.Enabled := FAniList.Count > 0;
  end;
end;

function TSkCustomAnimation.TProcess.GetTick: Double;
var
  LPerformanceCounter: Int64;
begin
  if FPerformanceFrequency = 0 then
    Result := timeGetTime / MSecsPerSec
  else
  begin
    QueryPerformanceCounter(LPerformanceCounter);
    Result := LPerformanceCounter / FPerformanceFrequency;
  end;
end;

procedure TSkCustomAnimation.TProcess.OnProcess(ASender: TObject);
var
  I: Integer;
  LNewTime: Double;
  LDeltaTime: Double;
  [unsafe] LAnimation: TSkCustomAnimation;
begin
  FrameRate := EnsureRange(FrameRate, 5, 120);
  FAnimation.Interval := Trunc(1000 / FrameRate);
  LNewTime := GetTick;
  LDeltaTime := LNewTime - FTime;
  if LDeltaTime < TimeEpsilon then
    Exit;
  FTime := LNewTime;
  if FAniList.Count > 0 then
  begin
    FAniProcessingList.AddRange(FAniList);
    I := FAniProcessingList.Count - 1;
    while I >= 0 do
    begin
      if I < FAniProcessingList.Count then
      begin
        LAnimation := FAniProcessingList[I];
        FAniProcessingList.Delete(I);
        if LAnimation.Running then
          LAnimation.ProcessTick(LDeltaTime);
        Dec(I);
      end
      else
        I := FAniProcessingList.Count - 1;
    end;
  end;
end;

class procedure TSkCustomAnimation.TProcess.Remove(
  const AAnimation: TSkCustomAnimation);
begin
  if FProcess <> nil then
    FProcess.DoRemove(AAnimation);
end;

{ TSkCustomAnimation }

procedure TSkCustomAnimation.BeforePaint;
begin
  if FNeedStart then
  begin
    if FAllowAnimation then
      InternalStart(False)
    else
      FNeedStartRepaint := True;
  end;
end;

function TSkCustomAnimation.CanProcessing: Boolean;
begin
  Result := FRunning and (not FPause) and (FSpeed >= SpeedEpsilon) and (FProcessDuration >= TimeEpsilon) and (FAllowAnimation or not FLoop);
end;

constructor TSkCustomAnimation.Create(const AOwner: TComponent);
begin
  inherited Create;
  FOwner := AOwner;
  Assign(nil);
end;

destructor TSkCustomAnimation.Destroy;
begin
  SetProcessing(False);
  inherited;
end;

procedure TSkCustomAnimation.DoAssign(ASource: TPersistent);
var
  LSourceAnimation: TSkCustomAnimation absolute ASource;
begin
  if ASource = nil then
  begin
    AutoReverse      := DefaultAutoReverse;
    Delay            := DefaultDelay;
    Enabled          := DefaultEnabled;
    Inverse          := DefaultInverse;
    Loop             := DefaultLoop;
    Pause            := DefaultPause;
    Speed            := DefaultSpeed;
    StartFromCurrent := DefaultStartFromCurrent;
    StartProgress    := DefaultStartProgress;
    StopProgress     := DefaultStopProgress;
    DoSetCurrentTime(0);
    SetRunning(False);
  end
  else if ASource is TSkCustomAnimation then
  begin
    AutoReverse      := LSourceAnimation.AutoReverse;
    Delay            := LSourceAnimation.Delay;
    Enabled          := LSourceAnimation.Enabled;
    Inverse          := LSourceAnimation.Inverse;
    Loop             := LSourceAnimation.Loop;
    Pause            := LSourceAnimation.Pause;
    Speed            := LSourceAnimation.Speed;
    StartFromCurrent := LSourceAnimation.StartFromCurrent;
    StartProgress    := LSourceAnimation.StartProgress;
    StopProgress     := LSourceAnimation.StopProgress;
    DoSetCurrentTime(LSourceAnimation.CurrentTime);
    SetRunning(LSourceAnimation.Running);
  end
  else
    inherited;
end;

procedure TSkCustomAnimation.DoChanged;
var
  LCanProcess: Boolean;
begin
  UpdateCurrentTime(FRunning, True);
  LCanProcess := FAllowAnimation;

  if FEnabledChanged then
  begin
    FEnabledChanged := False;
    if not FEnabled then
      Stop
    else if (not Assigned(FOwner)) or (not (csDesigning in FOwner.ComponentState)) then
    begin
      FNeedStart := True;
      FNeedStartRepaint := False;
    end;
  end;
  if FNeedStart and FNeedStartRepaint and FAllowAnimation then
  begin
    Start;
    LCanProcess := False;
  end;
  SetProcessing(CanProcessing);
  inherited;
  if LCanProcess then
    DoProcess;
end;

function TSkCustomAnimation.DoSetCurrentTime(const AValue: Double): Boolean;
begin
  Result := SetValue(FDelayTime, 0, TimeEpsilon);
  Result := SetValue(FCurrentTime, EnsureRange(AValue, 0, FDuration), TimeEpsilon) or Result;
end;

function TSkCustomAnimation.Equals(AObject: TObject): Boolean;
var
  LSourceAnimation: TSkCustomAnimation absolute AObject;
begin
  Result := (AObject is TSkCustomAnimation) and
    (FAutoReverse      = LSourceAnimation.AutoReverse) and
    (FEnabled          = LSourceAnimation.Enabled) and
    (FInverse          = LSourceAnimation.Inverse) and
    (FLoop             = LSourceAnimation.Loop) and
    (FPause            = LSourceAnimation.Pause) and
    (FStartFromCurrent = LSourceAnimation.StartFromCurrent) and
    (FRunning          = LSourceAnimation.Running) and
    SameValue(FCurrentTime, LSourceAnimation.CurrentTime, TimeEpsilon) and
    SameValue(FDelay, LSourceAnimation.Delay, TimeEpsilon) and
    SameValue(FSpeed, LSourceAnimation.Speed, SpeedEpsilon) and
    SameValue(FStartProgress, LSourceAnimation.StartProgress, ProgressEpsilon) and
    SameValue(FStopProgress, LSourceAnimation.StopProgress, ProgressEpsilon);
end;

function TSkCustomAnimation.GetDuration: Double;
begin
  Result := FDuration;
end;

procedure TSkCustomAnimation.InternalStart(const ACanProcess: Boolean);
begin
  FNeedStart := False;
  if not FLoop then
    FTickCount := 0;
  if FAutoReverse then
  begin
    if FRunning then
      FInverse := FSavedInverse
    else
      FSavedInverse := FInverse;
  end;
  if FProcessDuration < TimeEpsilon then
  begin
    SetStartValues(0, True);
    FRunning := True;
    DoStart;
    if ACanProcess and FAllowAnimation then
      DoProcess;
    FRunning := False;
    FProcessTime := 0;
    DoFinish;
  end
  else
  begin
    SetStartValues(FDelay, False);
    FRunning := True;
    FEnabled := True;
    SetProcessing(CanProcessing);

    if FDelay < TimeEpsilon then
    begin
      DoStart;
      if ACanProcess and FAllowAnimation then
        DoProcess;
    end
    else
      DoStart;
  end;
end;

function TSkCustomAnimation.IsDelayStored: Boolean;
begin
  Result := not SameValue(FDelay, DefaultDelay, TimeEpsilon);
end;

function TSkCustomAnimation.IsProgressStored: Boolean;
begin
  Result := not SameValue(FProgress, DefaultStartProgress, ProgressEpsilon);
end;

function TSkCustomAnimation.IsSpeedStored: Boolean;
begin
  Result := not SameValue(FSpeed, DefaultSpeed, SpeedEpsilon);
end;

function TSkCustomAnimation.IsStartProgressStored: Boolean;
begin
  Result := not SameValue(FStartProgress, DefaultStartProgress, ProgressEpsilon);
end;

function TSkCustomAnimation.IsStopProgressStored: Boolean;
begin
  Result := not SameValue(FStopProgress, DefaultStopProgress, ProgressEpsilon);
end;

procedure TSkCustomAnimation.ProcessTick(ADeltaTime: Double);
begin
  if Assigned(FOwner) and (csDestroying in FOwner.ComponentState) then
    Exit;
  SetProcessing(CanProcessing);
  if (not FRunning) or FPause or (FSpeed < SpeedEpsilon) or (not FProcessing) then
    Exit;

  if FDelayTime >= TimeEpsilon then
  begin
    FDelayTime := FDelayTime - ADeltaTime;
    if FDelayTime < TimeEpsilon then
    begin
      ADeltaTime := Max(-FDelayTime, 0);
      SetStartValues(0, False);
      if ADeltaTime < TimeEpsilon then
        Exit;
    end
    else
      Exit;
  end;

  if FInverse then
    FProcessTime := FProcessTime - ADeltaTime * FSpeed
  else
    FProcessTime := FProcessTime + ADeltaTime * FSpeed;
  if FProcessTime >= FProcessDuration then
  begin
    FProcessTime := FProcessDuration;
    if FLoop then
    begin
      if FAutoReverse then
      begin
        FInverse := True;
        FProcessTime := FProcessDuration;
      end
      else
        FProcessTime := 0;
    end
    else
      if FAutoReverse and (FTickCount = 0) then
      begin
        Inc(FTickCount);
        FInverse := True;
        FProcessTime := FProcessDuration;
      end
      else
        FRunning := False;
  end
  else if FProcessTime <= 0 then
  begin
    FProcessTime := 0;
    if FLoop then
    begin
      if FAutoReverse then
      begin
        FInverse := False;
        FProcessTime := 0;
      end
      else
        FProcessTime := FProcessDuration;
    end
    else
      if FAutoReverse and (FTickCount = 0) then
      begin
        Inc(FTickCount);
        FInverse := False;
        FProcessTime := 0;
      end
      else
        FRunning := False;
  end;
  UpdateCurrentTime(True, Updating);

  if not FRunning then
  begin
    if FAutoReverse then
      FInverse := FSavedInverse;
    FEnabled := False;
    SetProcessing(False);
  end;

  if FAllowAnimation then
    DoProcess;
  if not FRunning then
    DoFinish;
end;

procedure TSkCustomAnimation.SetAllowAnimation(const AValue: Boolean);
begin
  SetValue(FAllowAnimation, AValue);
end;

procedure TSkCustomAnimation.SetCurrentTime(const AValue: Double);
begin
  BeginUpdate;
  try
    FCurrentTimeChanged := DoSetCurrentTime(RoundTo(AValue, TimeRoundTo)) or FCurrentTimeChanged;
  finally
    EndUpdate;
  end;
end;

procedure TSkCustomAnimation.SetDelay(const AValue: Double);
begin
  FDelay := Max(0, RoundTo(AValue, TimeRoundTo));
  FDelayTime := Min(FDelayTime, FDelay);
end;

procedure TSkCustomAnimation.SetDuration(const AValue: Double);
begin
  SetValue(FDuration, Max(RoundTo(AValue, TimeRoundTo), 0), TimeEpsilon);
end;

procedure TSkCustomAnimation.SetEnabled(const AValue: Boolean);
begin
  BeginUpdate;
  try
    FEnabledChanged := SetValue(FEnabled, AValue) or FEnabledChanged;
  finally
    EndUpdate;
  end;
end;

procedure TSkCustomAnimation.SetLoop(const AValue: Boolean);
begin
  SetValue(FLoop, AValue);
end;

procedure TSkCustomAnimation.SetPause(const AValue: Boolean);
begin
  SetValue(FPause, AValue);
end;

procedure TSkCustomAnimation.SetProcessing(const AValue: Boolean);
begin
  if FProcessing <> AValue then
  begin
    FProcessing := AValue;
    if FProcessing then
      TProcess.Add(Self)
    else
      TProcess.Remove(Self);
  end;
end;

procedure TSkCustomAnimation.SetProgress(const AValue: Double);
begin
  FSavedProgress := AValue;
  CurrentTime := FDuration * EnsureRange(AValue, 0, 1);
end;

procedure TSkCustomAnimation.SetRunning(const AValue: Boolean);
begin
  SetValue(FRunning, AValue);
end;

procedure TSkCustomAnimation.SetSpeed(const AValue: Double);
begin
  SetValue(FSpeed, Max(RoundTo(AValue, SpeedRoundTo), 0), SpeedEpsilon);
end;

procedure TSkCustomAnimation.SetStartProgress(const AValue: Double);
begin
  SetValue(FStartProgress, EnsureRange(AValue, 0, 1), ProgressEpsilon);
end;

procedure TSkCustomAnimation.SetStartValues(const ADelayTime: Double; const AStartAtEnd: Boolean);
begin
  FDelayTime := ADelayTime;
  if FStartFromCurrent and not AStartAtEnd then
    FProcessTime := EnsureRange(FCurrentTime - Min(FStartProgress, FStopProgress) * FDuration, 0, FProcessDuration)
  else
    FProcessTime := IfThen(FInverse = AStartAtEnd, 0, FProcessDuration);
  UpdateCurrentTime(True, Updating);
end;

procedure TSkCustomAnimation.SetStopProgress(const AValue: Double);
begin
  SetValue(FStopProgress, EnsureRange(AValue, 0, 1), ProgressEpsilon);
end;

procedure TSkCustomAnimation.Start;
begin
  InternalStart(True);
end;

procedure TSkCustomAnimation.Stop;
begin
  FNeedStart := False;
  if not FRunning then
    Exit;
  if FAutoReverse then
    FInverse := FSavedInverse;
  if FInverse then
  begin
    FCurrentTime := 0;
    FProgress := 0;
  end
  else
  begin
    FCurrentTime := FProcessDuration;
    FProgress := 1;
  end;
  if FAllowAnimation then
    DoProcess;
  FRunning := False;
  FEnabled := False;
  SetProcessing(False);
  DoFinish;
end;

procedure TSkCustomAnimation.StopAtCurrent;
begin
  FNeedStart := False;
  if not FRunning then
    Exit;
  if FAutoReverse then
    FInverse := FSavedInverse;
  FRunning := False;
  FEnabled := False;
  SetProcessing(False);
  DoFinish;
end;

procedure TSkCustomAnimation.UpdateCurrentTime(const AIsRunning, ARecalcProcessDuration: Boolean);
begin
  if ARecalcProcessDuration then
  begin
    FProcessDuration := Abs(FStopProgress - FStartProgress) * FDuration;
    if FProcessDuration < TimeEpsilon then
      FProcessDuration := 0;
  end;
  if FCurrentTimeChanged and AIsRunning then
    FProcessTime := EnsureRange(FCurrentTime - Min(FStartProgress, FStopProgress) * FDuration, 0, FProcessDuration);
  if AIsRunning then
    FCurrentTime := Min(FStartProgress, FStopProgress) * FDuration + FProcessTime
  else
    FCurrentTime := EnsureRange(FCurrentTime, 0, FDuration);
  FCurrentTimeChanged := False;
  if FDuration < TimeEpsilon then
  begin
    if FInverse then
      FProgress := FStartProgress
    else
      FProgress := FStopProgress;
  end
  else
    FProgress := FCurrentTime / FDuration;
end;

{ TSkCustomAnimatedControl.TAnimationBase }

procedure TSkCustomAnimatedControl.TAnimationBase.DoChanged;
begin
  inherited;
  if Created then
    TSkCustomAnimatedControl(Owner).DoAnimationChanged;
end;

procedure TSkCustomAnimatedControl.TAnimationBase.DoFinish;
begin
  TSkCustomAnimatedControl(Owner).DoAnimationFinish;
end;

procedure TSkCustomAnimatedControl.TAnimationBase.DoProcess;
begin
  if FInsideDoProcess then
    Exit;
  FInsideDoProcess := True;
  try
    TSkCustomAnimatedControl(Owner).DoAnimationProcess;
  finally
    FInsideDoProcess := False;
  end;
end;

procedure TSkCustomAnimatedControl.TAnimationBase.DoStart;
begin
  TSkCustomAnimatedControl(Owner).DoAnimationStart;
end;

{ TSkCustomAnimatedControl }

function TSkCustomAnimatedControl.CanRunAnimation: Boolean;
begin
  Result := Assigned(Parent) and ([csDestroying, csLoading] * ComponentState = []) and
    AbsoluteVisible and (Width > 0) and (Height > 0) and (WindowHandle <> 0);
end;

procedure TSkCustomAnimatedControl.CheckAbsoluteVisible;
begin
  FAbsoluteVisibleCached := False;
  if Assigned(FAnimation) and FAnimation.Loop and FAnimation.Running and (not FAbsoluteVisible) and AbsoluteVisible then
    FAnimation.Start;
  CheckAnimation;
end;

procedure TSkCustomAnimatedControl.CheckAnimation;
begin
  if Assigned(FAnimation) then
    FAnimation.AllowAnimation := CanRunAnimation;
end;

procedure TSkCustomAnimatedControl.CheckDuration;
begin
  if Assigned(FAnimation) then
  begin
    if SameValue(FAnimation.Duration, 0, TAnimationBase.TimeEpsilon) then
      DrawCacheKind := TSkDrawCacheKind.Raster
    else
      DrawCacheKind := TSkDrawCacheKind.Never;
  end;
end;

procedure TSkCustomAnimatedControl.CMParentVisibleChanged(
  var AMessage: TMessage);
begin
  CheckAbsoluteVisible;
  inherited;
end;

procedure TSkCustomAnimatedControl.CMVisibleChanged(var AMessage: TMessage);
begin
  CheckAbsoluteVisible;
  inherited;
end;

constructor TSkCustomAnimatedControl.Create(AOwner: TComponent);
begin
  inherited;
  FAnimation := CreateAnimation;
  FAbsoluteVisible := Visible;
  FAbsoluteVisibleCached := True;
  CheckDuration;
  DrawParentInBackground := True;
end;

destructor TSkCustomAnimatedControl.Destroy;
begin
  FAnimation.Free;
  inherited;
end;

procedure TSkCustomAnimatedControl.DoAnimationChanged;
begin
  CheckDuration;
end;

procedure TSkCustomAnimatedControl.DoAnimationFinish;
begin
  if WindowHandle <> 0 then
    Paint;
  if Assigned(FOnAnimationFinish) then
    FOnAnimationFinish(Self);
end;

procedure TSkCustomAnimatedControl.DoAnimationProcess;
begin
  CheckAnimation;
  if WindowHandle <> 0 then
    Paint;
  if Assigned(FOnAnimationProcess) then
    FOnAnimationProcess(Self);
end;

procedure TSkCustomAnimatedControl.DoAnimationStart;
begin
  if Assigned(FOnAnimationStart) then
    FOnAnimationStart(Self);
end;

procedure TSkCustomAnimatedControl.Draw(const ACanvas: ISkCanvas;
  const ADest: TRectF; const AOpacity: Single);
begin
  inherited;
  if not FAnimation.AllowAnimation then
    CheckAnimation;
  FAnimation.BeforePaint;
  RenderFrame(ACanvas, ADest, FAnimation.Progress, AOpacity);
end;

function TSkCustomAnimatedControl.GetAbsoluteVisible: Boolean;

  function GetParentedVisible: Boolean;
  var
    LControl: TWinControl;
  begin
    if not Visible then
      Exit(False);
    LControl := Parent;
    while LControl <> nil do
    begin
      if not LControl.Visible then
        Exit(False);
      LControl := LControl.Parent;
    end;
    Result := True;
  end;

begin
  if not FAbsoluteVisibleCached then
  begin
    FAbsoluteVisible := GetParentedVisible;
    FAbsoluteVisibleCached := True;
  end;
  Result := FAbsoluteVisible;
end;

procedure TSkCustomAnimatedControl.ReadState(AReader: TReader);
begin
  FAnimation.BeginUpdate;
  try
    FAnimation.SavedProgress := FAnimation.Progress;
    inherited;
    FAnimation.Progress := FAnimation.SavedProgress;
  finally
    FAnimation.EndUpdate;
  end;
end;

procedure TSkCustomAnimatedControl.RenderFrame(const ACanvas: ISkCanvas;
  const ADest: TRectF; const AProgress: Double; const AOpacity: Single);
begin
  if Assigned(FOnAnimationDraw) then
    FOnAnimationDraw(Self, ACanvas, ADest, AProgress, AOpacity);
end;

procedure TSkCustomAnimatedControl.SetOnAnimationDraw(const AValue: TSkAnimationDrawEvent);
begin
  if TMethod(FOnAnimationDraw) <> TMethod(AValue) then
  begin
    FOnAnimationDraw := AValue;
    Redraw;
  end;
end;

{ TSkAnimatedPaintBox.TAnimation }

constructor TSkAnimatedPaintBox.TAnimation.Create(const AOwner: TComponent);
begin
  inherited Create(AOwner);
  Duration := DefaultDuration;
end;

procedure TSkAnimatedPaintBox.TAnimation.DoAssign(ASource: TPersistent);
var
  LSourceAnimation: TSkCustomAnimation absolute ASource;
begin
  if ASource = nil then
    Duration := DefaultDuration
  else if ASource is TSkCustomAnimation then
    Duration := LSourceAnimation.Duration;
  inherited;
end;

function TSkAnimatedPaintBox.TAnimation.Equals(AObject: TObject): Boolean;
var
  LSourceAnimation: TSkCustomAnimation absolute AObject;
begin
  Result := inherited and SameValue(Duration, LSourceAnimation.Duration, TimeEpsilon);
end;

function TSkAnimatedPaintBox.TAnimation.IsDurationStored: Boolean;
begin
  Result := not SameValue(Duration, DefaultDuration, TimeEpsilon);
end;

{ TSkAnimatedPaintBox }

function TSkAnimatedPaintBox.CreateAnimation: TSkCustomAnimatedControl.TAnimationBase;
begin
  Result := TAnimation.Create(Self);
end;

procedure TSkAnimatedPaintBox.DefineProperties(AFiler: TFiler);
begin
  inherited;
  // Backward compatibility with version 3
  AFiler.DefineProperty('Animate', ReadAnimate, nil, False);
  AFiler.DefineProperty('Duration', ReadDuration, nil, False);
  AFiler.DefineProperty('Loop', ReadLoop, nil, False);
end;

function TSkAnimatedPaintBox.GetAnimation: TSkAnimatedPaintBox.TAnimation;
begin
  Result := TSkAnimatedPaintBox.TAnimation(FAnimation);
end;

procedure TSkAnimatedPaintBox.ReadAnimate(AReader: TReader);
begin
  Animation.Enabled := AReader.ReadBoolean;
end;

procedure TSkAnimatedPaintBox.ReadDuration(AReader: TReader);
begin
  Animation.Duration := AReader.ReadFloat;
end;

procedure TSkAnimatedPaintBox.ReadLoop(AReader: TReader);
begin
  Animation.Loop := AReader.ReadBoolean;
end;

procedure TSkAnimatedPaintBox.SetAnimation(const AValue: TSkAnimatedPaintBox.TAnimation);
begin
  FAnimation.Assign(AValue);
end;

{ TSkAnimatedPaintBoxHelper }

function TSkAnimatedPaintBoxHelper.Animate: Boolean;
begin
  Result := Animation.Enabled;
end;

function TSkAnimatedPaintBoxHelper.Duration: Double;
begin
  Result := Animation.Duration;
end;

function TSkAnimatedPaintBoxHelper.FixedProgress: Boolean;
begin
  Result := not Animation.Enabled;
end;

function TSkAnimatedPaintBoxHelper.Loop: Boolean;
begin
  Result := Animation.Loop;
end;

function TSkAnimatedPaintBoxHelper.Progress: Double;
begin
  Result := Animation.Progress;
end;

function TSkAnimatedPaintBoxHelper.RunningAnimation: Boolean;
begin
  Result := Animation.Running;
end;

{ TSkAnimatedImage.TSource }

procedure TSkAnimatedImage.TSource.Assign(ASource: TPersistent);
begin
  if ASource is TSource then
    Data := TSource(ASource).Data
  else
    inherited;
end;

constructor TSkAnimatedImage.TSource.Create(const AOnChange: TNotifyEvent);
begin
  inherited Create;
  FOnChange := AOnChange;
end;

function TSkAnimatedImage.TSource.Equals(AObject: TObject): Boolean;
begin
  Result := (AObject is TSource) and IsSameBytes(FData, TSource(AObject).Data);
end;

procedure TSkAnimatedImage.TSource.SetData(const AValue: TBytes);
begin
  if not IsSameBytes(FData, AValue) then
  begin
    FData := Copy(AValue);
    if Assigned(FOnChange) then
      FOnChange(Self);
  end;
end;

{ TSkAnimatedImage.TFormatInfo }

constructor TSkAnimatedImage.TFormatInfo.Create(const AName,
  ADescription: string; const AExtensions: TArray<string>);
begin
  Name := AName;
  Description := ADescription;
  Extensions := AExtensions;
end;

{ TSkAnimatedImage }

constructor TSkAnimatedImage.Create(AOwner: TComponent);
begin
  inherited;
  FSource := TSource.Create(SourceChange);
end;

function TSkAnimatedImage.CreateAnimation: TSkCustomAnimatedControl.TAnimationBase;
begin
  Result := TAnimation.Create(Self);
end;

procedure TSkAnimatedImage.DefineProperties(AFiler: TFiler);

  function DoWrite: Boolean;
  begin
    if AFiler.Ancestor <> nil then
      Result := (not (AFiler.Ancestor is TSkAnimatedImage)) or not TSkAnimatedImage(AFiler.Ancestor).Source.Equals(FSource)
    else
      Result := FSource.Data <> nil;
  end;

begin
  inherited;
  AFiler.DefineBinaryProperty('Data', ReadData, WriteData, DoWrite);
  // Backward compatibility with version 3
  AFiler.DefineProperty('Loop', ReadLoop, nil, False);
  AFiler.DefineProperty('OnAnimationFinished', ReadOnAnimationFinished, nil, False);
  AFiler.DefineProperty('OnAnimationProgress', ReadOnAnimationProgress, nil, False);
end;

destructor TSkAnimatedImage.Destroy;
begin
  FCodec.Free;
  FSource.Free;
  inherited;
end;

procedure TSkAnimatedImage.Draw(const ACanvas: ISkCanvas; const ADest: TRectF;
  const AOpacity: Single);
begin
  if Assigned(FCodec) then
    inherited
  else if csDesigning in ComponentState then
    DrawDesignBorder(ACanvas, ADest, AOpacity);
end;

function TSkAnimatedImage.GetAnimation: TAnimation;
begin
  Result := TSkAnimatedImage.TAnimation(FAnimation);
end;

function TSkAnimatedImage.GetOriginalSize: TSizeF;
begin
  if Assigned(FCodec) then
    Result := FCodec.Size
  else
    Result := TSizeF.Create(0, 0);
end;

procedure TSkAnimatedImage.LoadFromFile(const AFileName: string);
begin
  FSource.Data := TFile.ReadAllBytes(AFileName);
end;

procedure TSkAnimatedImage.LoadFromStream(const AStream: TStream);
var
  LBytes: TBytes;
begin
  SetLength(LBytes, AStream.Size - AStream.Position);
  if Length(LBytes) > 0 then
    AStream.ReadBuffer(LBytes, 0, Length(LBytes));
  FSource.Data := LBytes;
end;

procedure TSkAnimatedImage.ReadData(AStream: TStream);
begin
  if AStream.Size = 0 then
    FSource.Data := nil
  else
    LoadFromStream(AStream);
end;

procedure TSkAnimatedImage.ReadLoop(AReader: TReader);
begin
  Animation.Loop := AReader.ReadBoolean;
end;

type
  TReaderAccess = class(TReader) end;

procedure TSkAnimatedImage.ReadOnAnimationFinished(AReader: TReader);
var
  LMethod: TMethod;
begin
  LMethod := TReaderAccess(AReader).FindMethodInstance(AReader.Root, AReader.ReadIdent);
  if LMethod.Code <> nil then
    OnAnimationFinish := TNotifyEvent(LMethod);
end;

procedure TSkAnimatedImage.ReadOnAnimationProgress(AReader: TReader);
var
  LMethod: TMethod;
begin
  LMethod := TReaderAccess(AReader).FindMethodInstance(AReader.Root, AReader.ReadIdent);
  if LMethod.Code <> nil then
    OnAnimationProcess := TNotifyEvent(LMethod);
end;

class procedure TSkAnimatedImage.RegisterCodec(
  const ACodecClass: TAnimationCodecClass);
begin
  FRegisteredCodecs := FRegisteredCodecs + [ACodecClass];
end;

procedure TSkAnimatedImage.RenderFrame(const ACanvas: ISkCanvas;
  const ADest: TRectF; const AProgress: Double; const AOpacity: Single);

  function GetWrappedRect(const ADest: TRectF): TRectF;
  var
    LImageRect: TRectF;
    LRatio: Single;
  begin
    LImageRect := TRectF.Create(PointF(0, 0), FCodec.Size);
    case FWrapMode of
      TSkAnimatedImageWrapMode.Fit: Result := LImageRect.FitInto(ADest);
      TSkAnimatedImageWrapMode.FitCrop:
        begin
          if (LImageRect.Width / ADest.Width) < (LImageRect.Height / ADest.Height) then
            LRatio := LImageRect.Width / ADest.Width
          else
            LRatio := LImageRect.Height / ADest.Height;
          if SameValue(LRatio, 0, TEpsilon.Vector) then
            Result := ADest
          else
          begin
            Result := RectF(0, 0, Round(LImageRect.Width / LRatio), Round(LImageRect.Height / LRatio));
            RectCenter(Result, ADest);
          end;
        end;
      TSkAnimatedImageWrapMode.Original:
        begin
          Result := LImageRect;
          Result.Offset(ADest.TopLeft);
        end;
      TSkAnimatedImageWrapMode.OriginalCenter:
        begin
          Result := LImageRect;
          RectCenter(Result, ADest);
        end;
      TSkAnimatedImageWrapMode.Place: Result := PlaceIntoTopLeft(LImageRect, ADest);
      TSkAnimatedImageWrapMode.Stretch: Result := ADest;
    end;
  end;

begin
  if Assigned(FCodec) then
  begin
    if (csDesigning in ComponentState) and (not Animation.Running) and (AProgress = 0) then
      FCodec.SeekFrameTime(Animation.Duration / 2)
    else
      FCodec.SeekFrameTime(Animation.CurrentTime);
    FCodec.Render(ACanvas, GetWrappedRect(ADest), AOpacity);
  end;
  inherited;
end;

procedure TSkAnimatedImage.SetAnimation(const AValue: TAnimation);
begin
  FAnimation.Assign(AValue);
end;

procedure TSkAnimatedImage.SetSource(const AValue: TSource);
begin
  FSource.Assign(AValue);
end;

procedure TSkAnimatedImage.SetWrapMode(const AValue: TSkAnimatedImageWrapMode);
begin
  if FWrapMode <> AValue then
  begin
    FWrapMode := AValue;
    Redraw;
  end;
end;

procedure TSkAnimatedImage.SourceChange(ASender: TObject);
var
  LCodecClass: TAnimationCodecClass;
  LStream: TStream;
begin
  FreeAndNil(FCodec);
  LStream := TBytesStream.Create(FSource.Data);
  try
    for LCodecClass in FRegisteredCodecs do
    begin
      LStream.Position := 0;
      if LCodecClass.TryMakeFromStream(LStream, FCodec) then
        Break;
    end;
  finally
    LStream.Free;
  end;
  if Assigned(FCodec) then
  begin
    Animation.SetDuration(FCodec.Duration);
    if Animation.Running then
      Animation.Start;
  end
  else
    Animation.SetDuration(0);
  Redraw;
end;

procedure TSkAnimatedImage.WriteData(AStream: TStream);
begin
  if FSource.Data <> nil then
    AStream.WriteBuffer(FSource.Data, Length(FSource.Data));
end;

{ TSkAnimatedImageHelper }

function TSkAnimatedImageHelper.Duration: Double;
begin
  Result := Animation.Duration;
end;

function TSkAnimatedImageHelper.FixedProgress: Boolean;
begin
  Result := not Animation.Enabled;
end;

function TSkAnimatedImageHelper.Loop: Boolean;
begin
  Result := Animation.Loop;
end;

function TSkAnimatedImageHelper.Progress: Double;
begin
  Result := Animation.Progress;
end;

function TSkAnimatedImageHelper.RunningAnimation: Boolean;
begin
  Result := Animation.Running;
end;

{ TSkDefaultAnimationCodec }

constructor TSkDefaultAnimationCodec.Create(
  const AAnimationCodec: ISkAnimationCodecPlayer; const AStream: TStream);
begin
  inherited Create;
  FAnimationCodec := AAnimationCodec;
  FStream := AStream;
end;

destructor TSkDefaultAnimationCodec.Destroy;
begin
  FStream.Free;
  inherited;
end;

function TSkDefaultAnimationCodec.GetDuration: Double;
begin
  Result := FAnimationCodec.Duration / 1000;
end;

function TSkDefaultAnimationCodec.GetFPS: Double;
begin
  Result := TSkCustomAnimation.DefaultFrameRate;
end;

function TSkDefaultAnimationCodec.GetIsStatic: Boolean;
begin
  Result := FAnimationCodec.Duration = 0;
end;

function TSkDefaultAnimationCodec.GetSize: TSizeF;
begin
  Result := FAnimationCodec.Dimensions;
end;

procedure TSkDefaultAnimationCodec.Render(const ACanvas: ISkCanvas;
  const ADest: TRectF; const AOpacity: Single);
var
  LPaint: ISkPaint;
begin
  if SameValue(AOpacity, 1, TEpsilon.Position) then
    LPaint := nil
  else
  begin
    LPaint := TSkPaint.Create;
    LPaint.AlphaF := AOpacity;
  end;
  ACanvas.DrawImageRect(FAnimationCodec.Frame, ADest, TSkSamplingOptions.Medium, LPaint);
end;

procedure TSkDefaultAnimationCodec.SeekFrameTime(const ATime: Double);
begin
  FAnimationCodec.Seek(Round(ATime * 1000));
end;

class function TSkDefaultAnimationCodec.SupportedFormats: TArray<TSkAnimatedImage.TFormatInfo>;
begin
  SetLength(Result, Ord(High(TImageFormat)) + 1);
  Result[Ord(TImageFormat.GIF)]  := TSkAnimatedImage.TFormatInfo.Create('GIF',  'GIF image',  ['.gif']);
  Result[Ord(TImageFormat.WebP)] := TSkAnimatedImage.TFormatInfo.Create('WebP', 'WebP image', ['.webp']);
end;

class function TSkDefaultAnimationCodec.TryDetectFormat(const ABytes: TBytes;
  out AFormat: TSkAnimatedImage.TFormatInfo): Boolean;

  function IsWebP: Boolean;
  const
    HeaderRiff: array[0..3] of Byte = ($52, $49, $46, $46);
    HeaderWebP: array[0..3] of Byte = ($57, $45, $42, $50);
  begin
    Result := (Length(ABytes) > 12) and
      CompareMem(@HeaderRiff[0], ABytes, Length(HeaderRiff)) and
      CompareMem(@HeaderWebP[0], @ABytes[8], Length(HeaderWebP));
  end;

const
  GIFSignature: array[0..2] of Byte = (71, 73, 70);
begin
  Result := True;
  if (Length(ABytes) >= Length(GIFSignature)) and CompareMem(@GIFSignature[0], ABytes, Length(GIFSignature)) then
    AFormat := SupportedFormats[Ord(TImageFormat.GIF)]
  else if IsWebP then
    AFormat := SupportedFormats[Ord(TImageFormat.WebP)]
  else
    Result := False;
end;

class function TSkDefaultAnimationCodec.TryMakeFromStream(
  const AStream: TStream; out ACodec: TSkAnimatedImage.TAnimationCodec): Boolean;
var
  LAnimationCodec: ISkAnimationCodecPlayer;
  LStream: TMemoryStream;
begin
  Result := False;
  LStream := TMemoryStream.Create;
  try
    LStream.CopyFrom(AStream, 0);
    LStream.Position := 0;
    LAnimationCodec := TSkAnimationCodecPlayer.MakeFromStream(LStream);
    if Assigned(LAnimationCodec) then
    begin
      ACodec := TSkDefaultAnimationCodec.Create(LAnimationCodec, LStream);
      Result := True;
    end
    else
      ACodec := nil;
  finally
    if not Result then
      LStream.Free;
  end;
end;

{ TSkLottieAnimationCodec }

constructor TSkLottieAnimationCodec.Create(const ASkottie: ISkottieAnimation);
begin
  inherited Create;
  FSkottie := ASkottie;
end;

function TSkLottieAnimationCodec.GetDuration: Double;
begin
  Result := FSkottie.Duration;
end;

function TSkLottieAnimationCodec.GetFPS: Double;
begin
  Result := FSkottie.FPS;
end;

function TSkLottieAnimationCodec.GetIsStatic: Boolean;
begin
  Result := False;
end;

function TSkLottieAnimationCodec.GetSize: TSizeF;
begin
  Result := FSkottie.Size;
end;

procedure TSkLottieAnimationCodec.Render(const ACanvas: ISkCanvas;
  const ADest: TRectF; const AOpacity: Single);
var
  LLottieRect: TRectF;
  LNeedSaveLayer: Boolean;
begin
  if ADest.IsEmpty then
    Exit;
  LLottieRect := TRectF.Create(PointF(0, 0), FSkottie.Size).FitInto(ADest);
  if LLottieRect.IsEmpty then
    Exit;
  LNeedSaveLayer := not SameValue(AOpacity, 1, TEpsilon.Position);
  if LNeedSaveLayer then
    ACanvas.SaveLayerAlpha(Round(AOpacity * 255));
  try
    if SameValue(ADest.Width / LLottieRect.Width, ADest.Height / LLottieRect.Height, TEpsilon.Matrix) then
      FSkottie.Render(ACanvas, ADest)
    else
    begin
      if not LNeedSaveLayer then
        ACanvas.Save;
      try
        ACanvas.Scale(ADest.Width / LLottieRect.Width, ADest.Height / LLottieRect.Height);
        ACanvas.Translate((LLottieRect.Width - ADest.Width) / 2, (LLottieRect.Height - ADest.Height) / 2);
        FSkottie.Render(ACanvas, ADest);
      finally
        if not LNeedSaveLayer then
          ACanvas.Restore;
      end;
    end;
  finally
    if LNeedSaveLayer then
      ACanvas.Restore;
  end;
end;

procedure TSkLottieAnimationCodec.SeekFrameTime(const ATime: Double);
begin
  FSkottie.SeekFrameTime(ATime);
end;

class function TSkLottieAnimationCodec.SupportedFormats: TArray<TSkAnimatedImage.TFormatInfo>;
begin
  SetLength(Result, Ord(High(TAnimationFormat)) + 1);
  Result[Ord(TAnimationFormat.Lottie)] := TSkAnimatedImage.TFormatInfo.Create('Lottie', 'Lottie file',      ['.json', '.lottie']);
  Result[Ord(TAnimationFormat.TGS)]    := TSkAnimatedImage.TFormatInfo.Create('TGS',    'Telegram sticker', ['.tgs']);
end;

class function TSkLottieAnimationCodec.TryDetectFormat(const ABytes: TBytes;
  out AFormat: TSkAnimatedImage.TFormatInfo): Boolean;
const
  GZipSignature: Word = $8B1F;
begin
  Result := False;
  if Length(ABytes) > 4 then
  begin
    if PWord(ABytes)^ = GZipSignature then
    begin
      AFormat := SupportedFormats[Ord(TAnimationFormat.TGS)];
      Result := True;
    end
    else if ((ABytes[0] = $7B) and (ABytes[Length(ABytes) - 1] = $7D)) or
        ((PWord(ABytes)^ = $7B00) and (PWord(@ABytes[Length(ABytes) - 2])^ = $7D00)) then
    begin
      AFormat := SupportedFormats[Ord(TAnimationFormat.Lottie)];
      Result := True;
    end;
  end;
end;

class function TSkLottieAnimationCodec.TryMakeFromStream(const AStream: TStream; out ACodec: TSkAnimatedImage.TAnimationCodec): Boolean;

  function IsTgs: Boolean;
  const
    GZipSignature: Word = $8B1F;
  var
    LSignature: Word;
    LSavePosition: Int64;
  begin
    if AStream.Size < 2 then
      Exit(False);
    LSavePosition := AStream.Position;
    try
      Result := (AStream.ReadData(LSignature) = SizeOf(Word)) and (LSignature = GZipSignature);
    finally
      AStream.Position := LSavePosition;
    end;
  end;

  function MakeFromTgsStream(const AStream: TStream): ISkottieAnimation;
  var
    LDecompressionStream: TDecompressionStream;
  begin
    LDecompressionStream := TDecompressionStream.Create(AStream, 31);
    try
      Result := TSkottieAnimation.MakeFromStream(LDecompressionStream);
    finally
      LDecompressionStream.Free;
    end;
  end;

var
  LSkottie: ISkottieAnimation;
begin
  if IsTgs then
    LSkottie := MakeFromTgsStream(AStream)
  else
    LSkottie := TSkottieAnimation.MakeFromStream(AStream);

  Result := Assigned(LSkottie);
  if Result then
    ACodec := TSkLottieAnimationCodec.Create(LSkottie)
  else
    ACodec := nil;
end;

{ TSkPersistentData }

procedure TSkPersistentData.AfterConstruction;
begin
  inherited;
  FCreated := True;
end;

procedure TSkPersistentData.Assign(ASource: TPersistent);
begin
  if ASource <> Self then
  begin
    BeginUpdate;
    try
      DoAssign(ASource);
    finally
      EndUpdate;
    end;
  end;
end;

procedure TSkPersistentData.BeginUpdate;
begin
  BeginUpdate(False);
end;

procedure TSkPersistentData.BeginUpdate(const AIgnoreAllChanges: Boolean);
begin
  Inc(FUpdatingCount);
  FIgnoringAllChanges := FIgnoringAllChanges or AIgnoreAllChanges;
end;

procedure TSkPersistentData.Change;
begin
  if FUpdatingCount > 0 then
    FChanged := True
  else
  begin
    FChanged := False;
    DoChanged;
  end;
end;

procedure TSkPersistentData.DoAssign(ASource: TPersistent);
begin
  inherited Assign(ASource);
end;

procedure TSkPersistentData.DoChanged;
begin
  if FCreated and Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TSkPersistentData.EndUpdate;
begin
  EndUpdate(False);
end;

procedure TSkPersistentData.EndUpdate(const AIgnoreAllChanges: Boolean);
var
  LCallChange: Boolean;
  LIgnoreChanges: Boolean;
begin
  LIgnoreChanges := AIgnoreAllChanges or FIgnoringAllChanges;
  LCallChange := False;
  if FUpdatingCount <= 0 then
    raise ESkPersistentData.Create('The object is not in update state');
  Dec(FUpdatingCount);
  if (not LIgnoreChanges) and HasChanged then
    LCallChange := True
  else
    FChanged := False;
  if FUpdatingCount <= 0 then
    FIgnoringAllChanges := False;
  if LCallChange and (FUpdatingCount = 0) then
  begin
    FChanged := False;
    DoChanged;
  end;
end;

function TSkPersistentData.GetHasChanged: Boolean;
begin
  Result := FChanged;
end;

function TSkPersistentData.GetUpdating: Boolean;
begin
  Result := FUpdatingCount > 0;
end;

function TSkPersistentData.SetValue(var AField: Byte; const AValue: Byte): Boolean;
begin
  Result := AField <> AValue;
  if Result then
  begin
    AField := AValue;
    Change;
  end;
end;

function TSkPersistentData.SetValue(var AField: Word; const AValue: Word): Boolean;
begin
  Result := AField <> AValue;
  if Result then
  begin
    AField := AValue;
    Change;
  end;
end;

function TSkPersistentData.SetValue(var AField: Double; const AValue,
  AEpsilon: Double): Boolean;
begin
  Result := not SameValue(AField, AValue, AEpsilon);
  if Result then
  begin
    AField := AValue;
    Change;
  end;
end;

function TSkPersistentData.SetValue(var AField: TBytes; const AValue: TBytes): Boolean;
begin
  Result := not IsSameBytes(AField, AValue);
  if Result then
  begin
    AField := Copy(AValue);
    Change;
  end;
end;

function TSkPersistentData.SetValue(var AField: string; const AValue: string): Boolean;
begin
  Result := AField <> AValue;
  if Result then
  begin
    AField := AValue;
    Change;
  end;
end;

function TSkPersistentData.SetValue(var AField: Single; const AValue,
  AEpsilon: Single): Boolean;
begin
  Result := not SameValue(AField, AValue, AEpsilon);
  if Result then
  begin
    AField := AValue;
    Change;
  end;
end;

function TSkPersistentData.SetValue(var AField: Boolean;
  const AValue: Boolean): Boolean;
begin
  Result := AField <> AValue;
  if Result then
  begin
    AField := AValue;
    Change;
  end;
end;

function TSkPersistentData.SetValue(var AField: Cardinal;
  const AValue: Cardinal): Boolean;
begin
  Result := AField <> AValue;
  if Result then
  begin
    AField := AValue;
    Change;
  end;
end;

function TSkPersistentData.SetValue(var AField: Integer;
  const AValue: Integer): Boolean;
begin
  Result := AField <> AValue;
  if Result then
  begin
    AField := AValue;
    Change;
  end;
end;

function TSkPersistentData.SetValue(var AField: Int64; const AValue: Int64): Boolean;
begin
  Result := AField <> AValue;
  if Result then
  begin
    AField := AValue;
    Change;
  end;
end;

function TSkPersistentData.SetValue<T>(var AField: T; const AValue: T): Boolean;
begin
  if Assigned(TypeInfo(T)) and (PTypeInfo(TypeInfo(T)).Kind in [TTypeKind.tkSet, TTypeKind.tkEnumeration, TTypeKind.tkRecord{$IF CompilerVersion >= 33}, TTypeKind.tkMRecord{$ENDIF}]) then
    Result := not CompareMem(@AField, @AValue, SizeOf(T))
  else
    Result := TComparer<T>.Default.Compare(AField, AValue) <> 0;
  if Result then
  begin
    AField := AValue;
    Change;
  end;
end;

{ TSkFontComponent }

procedure TSkFontComponent.AssignTo(ADest: TPersistent);
var
  LDestFont: TFont absolute ADest;
  LStyle: TFontStyles;
begin
  if ADest is TFont then
  begin
    LDestFont.Name  := Families;
    LDestFont.Size  := Round(Size);
    LStyle := [];
    if Weight >= TSkFontWeight.Medium then
    begin
      Include(LStyle, fsBold);
    end;
    if Slant in [TSkFontSlant.Italic, TSkFontSlant.Oblique] then
      Include(LStyle, fsItalic);
    LDestFont.Style := LStyle;
  end
  else
    inherited;
end;

constructor TSkFontComponent.Create;
begin
  inherited Create;
  Assign(nil);
end;

procedure TSkFontComponent.DoAssign(ASource: TPersistent);
var
  LSourceFont: TSkFontComponent absolute ASource;
begin
  if ASource = nil then
  begin
    Families := DefaultFamilies;
    Size     := DefaultSize;
    Slant    := DefaultSlant;
    Stretch  := DefaultStretch;
    Weight   := DefaultWeight;
  end
  else if ASource is TSkFontComponent then
  begin
    Families := LSourceFont.Families;
    Size     := LSourceFont.Size;
    Slant    := LSourceFont.Slant;
    Stretch  := LSourceFont.Stretch;
    Weight   := LSourceFont.Weight;
  end
  else if ASource is TFont then
  begin
    Families := TFont(ASource).Name;
    Size     := TFont(ASource).Size;
    Stretch  := TSkFontStretch.Regular;
    if TFontStyle.fsItalic in TFont(ASource).Style then
      Slant := TSkFontSlant.Oblique
    else
      Slant := TSkFontSlant.Regular;
    if TFontStyle.fsBold in TFont(ASource).Style then
      Weight := TSkFontWeight.Bold
    else
      Weight := TSkFontWeight.Regular;
  end
  else
    inherited;
end;

function TSkFontComponent.Equals(AObject: TObject): Boolean;
var
  LFont: TSkFontComponent absolute AObject;
begin
  Result := (AObject is TSkFontComponent) and
    (FFamilies = LFont.Families) and
    (FSlant    = LFont.Slant) and
    (FStretch  = LFont.Stretch) and
    (FWeight   = LFont.Weight) and
    SameValue(FSize, LFont.Size, TEpsilon.FontSize);
end;

function TSkFontComponent.IsFamiliesStored: Boolean;
begin
  Result := FFamilies <> DefaultFamilies;
end;

function TSkFontComponent.IsSizeStored: Boolean;
begin
  Result := not SameValue(FSize, DefaultSize, TEpsilon.FontSize);
end;

procedure TSkFontComponent.SetFamilies(const AValue: string);

  function NormalizeFamilies(const AValue: string): string;
  var
    LSplitted: TArray<string>;
    LFamilies: TArray<string>;
    I: Integer;
  begin
    LSplitted := AValue.Split([',', #13, #10], TStringSplitOptions.ExcludeEmpty);
    LFamilies := [];
    for I := 0 to Length(LSplitted) - 1 do
    begin
      LSplitted[I] := LSplitted[I].Trim;
      if LSplitted[I] <> '' then
        LFamilies := LFamilies + [LSplitted[I]];
    end;
    if LFamilies = nil then
      Exit('');
    Result := string.Join(', ', LFamilies);
  end;

begin
  SetValue(FFamilies, NormalizeFamilies(AValue));
end;

procedure TSkFontComponent.SetSize(const AValue: Single);
begin
  SetValue(FSize, AValue, TEpsilon.FontSize);
end;

procedure TSkFontComponent.SetSlant(const AValue: TSkFontSlant);
begin
  SetValue<TSkFontSlant>(FSlant, AValue);
end;

procedure TSkFontComponent.SetStretch(const AValue: TSkFontStretch);
begin
  SetValue<TSkFontStretch>(FStretch, AValue);
end;

procedure TSkFontComponent.SetWeight(const AValue: TSkFontWeight);
begin
  SetValue<TSkFontWeight>(FWeight, AValue);
end;

{ TSkTextSettings.TDecorations }

constructor TSkTextSettings.TDecorations.Create;
begin
  inherited Create;
  Assign(nil);
end;

procedure TSkTextSettings.TDecorations.DoAssign(ASource: TPersistent);
var
  LSourceDecorations: TDecorations absolute ASource;
begin
  if ASource = nil then
  begin
    Color       := DefaultColor;
    Decorations := DefaultDecorations;
    StrokeColor := DefaultStrokeColor;
    Style       := DefaultStyle;
    Thickness   := DefaultThickness;
  end
  else if ASource is TDecorations then
  begin
    Color       := LSourceDecorations.Color;
    Decorations := LSourceDecorations.Decorations;
    StrokeColor := LSourceDecorations.StrokeColor;
    Style       := LSourceDecorations.Style;
    Thickness   := LSourceDecorations.Thickness;
  end
  else
    inherited;
end;

function TSkTextSettings.TDecorations.Equals(AObject: TObject): Boolean;
var
  LDecorations: TDecorations absolute AObject;
begin
  Result := (AObject is TDecorations) and
    (Color       = LDecorations.Color) and
    (Decorations = LDecorations.Decorations) and
    (StrokeColor = LDecorations.StrokeColor) and
    (Style       = LDecorations.Style) and
    (Thickness   = LDecorations.Thickness);
end;

function TSkTextSettings.TDecorations.IsThicknessStored: Boolean;
begin
  Result := not SameValue(FThickness, DefaultThickness, TEpsilon.Scale);
end;

procedure TSkTextSettings.TDecorations.SetColor(const AValue: TAlphaColor);
begin
  SetValue<TAlphaColor>(FColor, AValue);
end;

procedure TSkTextSettings.TDecorations.SetDecorations(
  const AValue: TSkTextDecorations);
begin
  SetValue<TSkTextDecorations>(FDecorations, AValue);
end;

procedure TSkTextSettings.TDecorations.SetStrokeColor(
  const AValue: TAlphaColor);
begin
  SetValue<TAlphaColor>(FStrokeColor, AValue);
end;

procedure TSkTextSettings.TDecorations.SetStyle(
  const AValue: TSkTextDecorationStyle);
begin
  SetValue<TSkTextDecorationStyle>(FStyle, AValue);
end;

procedure TSkTextSettings.TDecorations.SetThickness(
  const AValue: Single);
begin
  SetValue(FThickness, AValue);
end;

{ TSkTextSettings }

procedure TSkTextSettings.AssignNotStyled(const ATextSettings: TSkTextSettings;
  const AStyledSettings: TSkStyledSettings);
var
  LTextSettings: TSkTextSettings;
begin
  if AStyledSettings <> AllStyledSettings then
  begin
    if AStyledSettings = [] then
      Assign(ATextSettings)
    else
    begin
      if ATextSettings = nil then
        LTextSettings := TSkTextSettingsClass(ClassType).Create(Owner)
      else
        LTextSettings := ATextSettings;
      try
        BeginUpdate;
        try
          DoAssignNotStyled(LTextSettings, AStyledSettings);
        finally
          EndUpdate;
        end;
      finally
        if ATextSettings = nil then
          LTextSettings.Free;
      end;
    end;
  end;
end;

constructor TSkTextSettings.Create(const AOwner: TPersistent);
begin
  inherited Create;
  FOwner := AOwner;
  FFont := TSkFontComponent.Create;
  FFont.OnChange := FontChanged;
  FDecorations := TDecorations.Create;
  FDecorations.OnChange := DecorationsChange;
  Assign(nil);
end;

procedure TSkTextSettings.DecorationsChange(ASender: TObject);
begin
  Change;
end;

destructor TSkTextSettings.Destroy;
begin
  FDecorations.Free;
  FFont.Free;
  inherited;
end;

procedure TSkTextSettings.DoAssign(ASource: TPersistent);
var
  LSourceTextSettings: TSkTextSettings absolute ASource;
begin
  if ASource = nil then
  begin
    Decorations      := nil;
    Font             := nil;
    FontColor        := DefaultFontColor;
    HeightMultiplier := DefaultHeightMultiplier;
    HorzAlign        := DefaultHorzAlign;
    LetterSpacing    := DefaultLetterSpacing;
    MaxLines         := DefaultMaxLines;
    Trimming         := DefaultTrimming;
    VertAlign        := DefaultVertAlign;
  end
  else if ASource is TSkTextSettings then
  begin
    Decorations      := LSourceTextSettings.Decorations;
    Font             := LSourceTextSettings.Font;
    FontColor        := LSourceTextSettings.FontColor;
    HeightMultiplier := LSourceTextSettings.HeightMultiplier;
    HorzAlign        := LSourceTextSettings.HorzAlign;
    LetterSpacing    := LSourceTextSettings.LetterSpacing;
    MaxLines         := LSourceTextSettings.MaxLines;
    Trimming         := LSourceTextSettings.Trimming;
    VertAlign        := LSourceTextSettings.VertAlign;
  end
  else
    inherited;
end;

procedure TSkTextSettings.DoAssignNotStyled(
  const ATextSettings: TSkTextSettings; const AStyledSettings: TSkStyledSettings);
begin
  Font.BeginUpdate;
  try
    if not (TSkStyledSetting.Family in AStyledSettings) then
      Font.Families := ATextSettings.Font.Families;
    if not (TSkStyledSetting.Size in AStyledSettings) then
      Font.Size := ATextSettings.Font.Size;
    if not (TSkStyledSetting.Style in AStyledSettings) then
    begin
      Font.Slant   := ATextSettings.Font.Slant;
      Font.Stretch := ATextSettings.Font.Stretch;
      Font.Weight  := ATextSettings.Font.Weight;
    end;
  finally
    Font.EndUpdate;
  end;
  if not (TSkStyledSetting.FontColor in AStyledSettings) then
    FontColor := ATextSettings.FontColor;
  if not (TSkStyledSetting.Other in AStyledSettings) then
  begin
    Decorations      := ATextSettings.Decorations;
    HeightMultiplier := ATextSettings.HeightMultiplier;
    HorzAlign        := ATextSettings.HorzAlign;
    LetterSpacing    := ATextSettings.LetterSpacing;
    VertAlign        := ATextSettings.VertAlign;
    MaxLines         := ATextSettings.MaxLines;
    Trimming         := ATextSettings.Trimming;
  end;
end;

function TSkTextSettings.Equals(AObject: TObject): Boolean;
var
  LTextSettings: TSkTextSettings absolute AObject;
begin
  Result := (AObject is TSkTextSettings) and
    FDecorations.Equals(LTextSettings.Decorations) and
    FFont.Equals(LTextSettings.Font) and
    (FFontColor        = LTextSettings.FontColor) and
    (FHeightMultiplier = LTextSettings.HeightMultiplier) and
    (FHorzAlign        = LTextSettings.HorzAlign) and
    (FLetterSpacing    = LTextSettings.LetterSpacing) and
    (FMaxLines         = LTextSettings.MaxLines) and
    (FTrimming         = LTextSettings.Trimming) and
    (FVertAlign        = LTextSettings.VertAlign);
end;

procedure TSkTextSettings.FontChanged(ASender: TObject);
begin
  Change;
end;

function TSkTextSettings.IsHeightMultiplierStored: Boolean;
begin
  Result := not SameValue(FHeightMultiplier, DefaultHeightMultiplier, TEpsilon.Position);
end;

function TSkTextSettings.IsLetterSpacingStored: Boolean;
begin
  Result := not SameValue(FLetterSpacing, DefaultLetterSpacing, TEpsilon.Position);
end;

procedure TSkTextSettings.SetDecorations(const AValue: TDecorations);
begin
  FDecorations.Assign(AValue);
end;

procedure TSkTextSettings.SetFont(const AValue: TSkFontComponent);
begin
  FFont.Assign(AValue);
end;

procedure TSkTextSettings.SetFontColor(const AValue: TAlphaColor);
begin
  SetValue<TAlphaColor>(FFontColor, AValue);
end;

procedure TSkTextSettings.SetHeightMultiplier(const AValue: Single);
begin
  SetValue(FHeightMultiplier, AValue, TEpsilon.Position);
end;

procedure TSkTextSettings.SetHorzAlign(const AValue: TSkTextHorzAlign);
begin
  SetValue<TSkTextHorzAlign>(FHorzAlign, AValue);
end;

procedure TSkTextSettings.SetLetterSpacing(const AValue: Single);
begin
  SetValue(FLetterSpacing, AValue, TEpsilon.Position);
end;

procedure TSkTextSettings.SetMaxLines(const AValue: NativeUInt);
begin
  SetValue<NativeUInt>(FMaxLines, AValue);
end;

procedure TSkTextSettings.SetTrimming(const AValue: TSkTextTrimming);
begin
  SetValue<TSkTextTrimming>(FTrimming, AValue);
end;

procedure TSkTextSettings.SetVertAlign(const AValue: TSkTextVertAlign);
begin
  SetValue<TSkTextVertAlign>(FVertAlign, AValue);
end;

procedure TSkTextSettings.UpdateStyledSettings(const AOldTextSettings,
  ADefaultTextSettings: TSkTextSettings; var AStyledSettings: TSkStyledSettings);
begin
  // If the user changed the value of the property, and it differs from the default,
  // then delete the corresponding value from AStyledSettings
  if (not SameText(AOldTextSettings.Font.Families, Font.Families)) and
    (not SameText(ADefaultTextSettings.Font.Families, Font.Families)) then
  begin
    Exclude(AStyledSettings, TSkStyledSetting.Family);
  end;

  if (not SameValue(AOldTextSettings.Font.Size, Font.Size, TEpsilon.FontSize)) and
    (not SameValue(ADefaultTextSettings.Font.Size, Font.Size, TEpsilon.FontSize)) then
  begin
    Exclude(AStyledSettings, TSkStyledSetting.Size);
  end;

  if ((AOldTextSettings.Font.Slant <> Font.Slant) or (AOldTextSettings.Font.Stretch <> Font.Stretch) or
    (AOldTextSettings.Font.Weight <> Font.Weight)) and
    ((ADefaultTextSettings.Font.Slant <> Font.Slant) or (ADefaultTextSettings.Font.Stretch <> Font.Stretch) or
    (ADefaultTextSettings.Font.Weight <> Font.Weight)) then
  begin
    Exclude(AStyledSettings, TSkStyledSetting.Style);
  end;

  if ((AOldTextSettings.FontColor <> FontColor) and (ADefaultTextSettings.FontColor <> FontColor)) then
    Exclude(AStyledSettings, TSkStyledSetting.FontColor);

  if ((not AOldTextSettings.Decorations.Equals(Decorations)) or
    (AOldTextSettings.HeightMultiplier <> HeightMultiplier) or
    (AOldTextSettings.HorzAlign <> HorzAlign) or (AOldTextSettings.VertAlign <> VertAlign) or
    (AOldTextSettings.LetterSpacing <> LetterSpacing) or
    (AOldTextSettings.Trimming <> Trimming) or (AOldTextSettings.MaxLines <> MaxLines)) and
    ((not ADefaultTextSettings.Decorations.Equals(Decorations)) or
    (ADefaultTextSettings.HeightMultiplier <> HeightMultiplier) or
    (ADefaultTextSettings.HorzAlign <> HorzAlign) or (ADefaultTextSettings.VertAlign <> VertAlign) or
    (ADefaultTextSettings.LetterSpacing <> LetterSpacing) or
    (ADefaultTextSettings.Trimming <> Trimming) or (ADefaultTextSettings.MaxLines <> MaxLines)) then
  begin
    Exclude(AStyledSettings, TSkStyledSetting.Other);
  end;
end;

{ TSkTextSettingsInfo.TBaseTextSettings }

constructor TSkTextSettingsInfo.TBaseTextSettings.Create(
  const AOwner: TPersistent);
begin
  inherited;
  if AOwner is TSkTextSettingsInfo then
  begin
    FInfo := TSkTextSettingsInfo(AOwner);
    if FInfo.Owner is TControl then
      FControl := TControl(FInfo.Owner);
  end;
end;

{ TSkTextSettingsInfo.TCustomTextSettings }

constructor TSkTextSettingsInfo.TCustomTextSettings.Create(
  const AOwner: TPersistent);
begin
  inherited;
  MaxLines := 0;
end;

{ TSkTextSettingsInfo }

constructor TSkTextSettingsInfo.Create(AOwner: TPersistent;
  ATextSettingsClass: TSkTextSettingsInfo.TCustomTextSettingsClass);
var
  LClass: TSkTextSettingsInfo.TCustomTextSettingsClass;
begin
  if AOwner = nil then
    raise ESkTextSettingsInfo.Create(SArgumentNil);
  inherited Create;
  FOwner := AOwner;
  FStyledSettings := DefaultStyledSettings;
  if ATextSettingsClass = nil then
    LClass := TCustomTextSettings
  else
    LClass := ATextSettingsClass;

  FDefaultTextSettings := LClass.Create(Self);
  FDefaultTextSettings.OnChange := OnDefaultChanged;
  FTextSettings := LClass.Create(Self);
  FTextSettings.OnChange := OnTextChanged;
  FResultingTextSettings := LClass.Create(Self);
  FResultingTextSettings.OnChange := OnCalculatedTextSettings;
  FOldTextSettings := LClass.Create(Self);
  FOldTextSettings.Assign(FTextSettings);
end;

destructor TSkTextSettingsInfo.Destroy;
begin
  FDefaultTextSettings.Free;
  FTextSettings.Free;
  FResultingTextSettings.Free;
  FOldTextSettings.Free;
  inherited;
end;

procedure TSkTextSettingsInfo.DoCalculatedTextSettings;
begin
end;

procedure TSkTextSettingsInfo.DoDefaultChanged;
begin
  RecalculateTextSettings;
end;

procedure TSkTextSettingsInfo.DoStyledSettingsChanged;
begin
  RecalculateTextSettings;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TSkTextSettingsInfo.DoTextChanged;
var
  LDesign: Boolean;
begin
  try
    LDesign := Design and (not (Owner is TComponent) or
      (TComponent(Owner).ComponentState * [csLoading, csDestroying, csReading] = []));
    if LDesign then
      TextSettings.UpdateStyledSettings(FOldTextSettings, DefaultTextSettings, FStyledSettings);
    RecalculateTextSettings;
  finally
    if FOldTextSettings <> nil then
      FOldTextSettings.Assign(FTextSettings);
  end;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TSkTextSettingsInfo.OnCalculatedTextSettings(ASender: TObject);
begin
  DoCalculatedTextSettings;
end;

procedure TSkTextSettingsInfo.OnDefaultChanged(ASender: TObject);
begin
  DoDefaultChanged;
end;

procedure TSkTextSettingsInfo.OnTextChanged(ASender: TObject);
begin
  DoTextChanged;
end;

procedure TSkTextSettingsInfo.RecalculateTextSettings;
var
  TmpResultingTextSettings: TSkTextSettings;
begin
  if ResultingTextSettings <> nil then
  begin
    TmpResultingTextSettings := TSkTextSettingsClass(TextSettings.ClassType).Create(Self);
    try
      TmpResultingTextSettings.Assign(DefaultTextSettings);
      TmpResultingTextSettings.AssignNotStyled(TextSettings, StyledSettings);
      ResultingTextSettings.Assign(TmpResultingTextSettings);
    finally
      TmpResultingTextSettings.Free;
    end;
  end;
end;

procedure TSkTextSettingsInfo.SetDefaultTextSettings(
  const AValue: TSkTextSettings);
begin
  FDefaultTextSettings.Assign(AValue);
end;

procedure TSkTextSettingsInfo.SetStyledSettings(const AValue: TSkStyledSettings);
begin
  if FStyledSettings <> AValue then
  begin
    FStyledSettings := AValue;
    DoStyledSettingsChanged;
  end;
end;

procedure TSkTextSettingsInfo.SetTextSettings(const AValue: TSkTextSettings);
begin
  FTextSettings.Assign(AValue);
end;

{ TSkLabel.TCustomWordsItem }

procedure TSkLabel.TCustomWordsItem.Assign(ASource: TPersistent);
begin
  if ASource <> Self then
  begin
    BeginUpdate;
    try
      DoAssign(ASource);
    finally
      EndUpdate;
    end;
  end;
end;

procedure TSkLabel.TCustomWordsItem.BeginUpdate;
begin
  Inc(FUpdatingCount);
end;

procedure TSkLabel.TCustomWordsItem.Change;
begin
  if FUpdatingCount > 0 then
    FChanged := True
  else
  begin
    FChanged := False;
    DoChanged;
  end;
end;

procedure TSkLabel.TCustomWordsItem.CheckName(const AName: string;
  AWordsCollection: TWordsCollection);
var
  I: Integer;
begin
  if AName.Trim.IsEmpty then
    raise ESkLabel.CreateFmt(SInvalidName, [AName]);
  if AWordsCollection <> nil then
    for I := 0 to AWordsCollection.Count - 1 do
      if (AWordsCollection.Items[I] <> Self) and (string.Compare(AName, AWordsCollection.Items[I].Name, [TCompareOption.coIgnoreCase]) = 0) then
        raise ESkLabel.CreateFmt(SDuplicateName, [AWordsCollection.Items[I].Name]);
end;

constructor TSkLabel.TCustomWordsItem.Create(ACollection: TCollection);
var
  LTextSettingsInfoOwner: TPersistent;
begin
  inherited;
  if (ACollection is TWordsCollection) and Assigned(TWordsCollection(ACollection).&Label) then
    LTextSettingsInfoOwner := TWordsCollection(ACollection).&Label
  else
    LTextSettingsInfoOwner := Self;
  FTextSettingsInfo := TSkTextSettingsInfo.Create(LTextSettingsInfoOwner, nil);
  if LTextSettingsInfoOwner is TSkLabel then
    FTextSettingsInfo.Design := True;
  Assign(nil);
  FTextSettingsInfo.OnChange := TextSettingsChange;
end;

destructor TSkLabel.TCustomWordsItem.Destroy;
begin
  FTextSettingsInfo.Free;
  inherited;
end;

procedure TSkLabel.TCustomWordsItem.DoAssign(ASource: TPersistent);
var
  LSourceItem: TCustomWordsItem absolute ASource;
begin
  if ASource = nil then
  begin
    BackgroundColor  := DefaultBackgroundColor;
    Caption          := DefaultCaption;
    Cursor           := DefaultCursor;
    Font             := nil;
    FontColor        := DefaultFontColor;
    HeightMultiplier := DefaultHeightMultiplier;
    LetterSpacing    := DefaultLetterSpacing;
    Name             := UniqueName(DefaultName, Collection);
    StyledSettings   := DefaultStyledSettings;
    OnClick          := nil;
  end
  else if ASource is TCustomWordsItem then
  begin
    BackgroundColor  := LSourceItem.BackgroundColor;
    Caption          := LSourceItem.Caption;
    Cursor           := LSourceItem.Cursor;
    Font             := LSourceItem.Font;
    FontColor        := LSourceItem.FontColor;
    HeightMultiplier := LSourceItem.HeightMultiplier;
    LetterSpacing    := LSourceItem.LetterSpacing;
    Name             := UniqueName(LSourceItem.Name, Collection);
    StyledSettings   := LSourceItem.StyledSettings;
    OnClick          := LSourceItem.OnClick;
  end
  else
    inherited Assign(ASource);
end;

procedure TSkLabel.TCustomWordsItem.DoChanged;
begin
  Changed(False);
end;

procedure TSkLabel.TCustomWordsItem.EndUpdate;
begin
  EndUpdate(False);
end;

procedure TSkLabel.TCustomWordsItem.EndUpdate(const AIgnoreAllChanges: Boolean);
var
  LCallChange: Boolean;
  LIgnoreChanges: Boolean;
begin
  LIgnoreChanges := AIgnoreAllChanges or FIgnoringAllChanges;
  LCallChange := False;
  if FUpdatingCount <= 0 then
    raise ESkLabel.Create('The object is not in update state');
  Dec(FUpdatingCount);
  if (not LIgnoreChanges) and FChanged then
    LCallChange := True
  else
    FChanged := False;
  if FUpdatingCount <= 0 then
    FIgnoringAllChanges := False;
  if LCallChange and (FUpdatingCount = 0) then
  begin
    FChanged := False;
    DoChanged;
  end;
end;

function TSkLabel.TCustomWordsItem.GetDecorations: TSkTextSettings.TDecorations;
begin
  Result := FTextSettingsInfo.TextSettings.Decorations;
end;

function TSkLabel.TCustomWordsItem.GetDisplayName: string;
begin
  Result := Name;
end;

function TSkLabel.TCustomWordsItem.GetFont: TSkFontComponent;
begin
  Result := FTextSettingsInfo.TextSettings.Font;
end;

function TSkLabel.TCustomWordsItem.GetFontColor: TAlphaColor;
begin
  Result := FTextSettingsInfo.TextSettings.FontColor;
end;

function TSkLabel.TCustomWordsItem.GetHeightMultiplier: Single;
begin
  Result := FTextSettingsInfo.TextSettings.HeightMultiplier;
end;

function TSkLabel.TCustomWordsItem.GetLetterSpacing: Single;
begin
  Result := FTextSettingsInfo.TextSettings.LetterSpacing;
end;

function TSkLabel.TCustomWordsItem.GetStyledSettings: TSkStyledSettings;
begin
  Result := FTextSettingsInfo.StyledSettings;
end;

function TSkLabel.TCustomWordsItem.IsCaptionStored: Boolean;
begin
  Result := Caption <> DefaultCaption;
end;

function TSkLabel.TCustomWordsItem.IsFontColorStored: Boolean;
begin
  Result := (FontColor <> DefaultFontColor) or not (TSkStyledSetting.FontColor in StyledSettings);
end;

function TSkLabel.TCustomWordsItem.IsHeightMultiplierStored: Boolean;
begin
  Result := (not SameValue(HeightMultiplier, DefaultHeightMultiplier, TEpsilon.Position)) or not (TSkStyledSetting.Other in StyledSettings);
end;

function TSkLabel.TCustomWordsItem.IsLetterSpacingStored: Boolean;
begin
  Result := (not SameValue(LetterSpacing, DefaultLetterSpacing, TEpsilon.Position)) or not (TSkStyledSetting.Other in StyledSettings);
end;

function TSkLabel.TCustomWordsItem.IsNameStored: Boolean;
begin
  Result := (Assigned(Collection) and (Collection.Count <> 1)) or (Name <> 'Item 0');
end;

function TSkLabel.TCustomWordsItem.IsStyledSettingsStored: Boolean;
begin
  Result := StyledSettings <> DefaultStyledSettings;
end;

procedure TSkLabel.TCustomWordsItem.SetBackgroundColor(
  const AValue: TAlphaColor);
begin
  if FBackgroundColor <> AValue then
  begin
    FBackgroundColor := AValue;
    Change;
  end;
end;

procedure TSkLabel.TCustomWordsItem.SetCaption(const AValue: string);
begin
  if FCaption <> AValue then
  begin
    FCaption := AValue;
    Change;
  end;
end;

procedure TSkLabel.TCustomWordsItem.SetCollection(AValue: TCollection);
var
  S: string;
begin
  if Assigned(AValue) and not (AValue is TWordsCollection) then
    raise ESkLabel.Create('You can use only the inheritors of class "TWordsCollection"');
  S := UniqueName(FName, AValue);
  if string.Compare(S, FName, [TCompareOption.coIgnoreCase]) <> 0 then
    CheckName(S, TWordsCollection(AValue));
  FName := S;
  inherited;
  FWords := TWordsCollection(Collection);
end;

procedure TSkLabel.TCustomWordsItem.SetCursor(const AValue: TCursor);
begin
  if FCursor <> AValue then
  begin
    FCursor := AValue;
    Change;
  end;
end;

procedure TSkLabel.TCustomWordsItem.SetDecorations(
  const AValue: TSkTextSettings.TDecorations);
begin
  FTextSettingsInfo.TextSettings.Decorations.Assign(AValue);
end;

procedure TSkLabel.TCustomWordsItem.SetFont(const AValue: TSkFontComponent);
begin
  FTextSettingsInfo.TextSettings.Font.Assign(AValue);
end;

procedure TSkLabel.TCustomWordsItem.SetFontColor(const AValue: TAlphaColor);
begin
  FTextSettingsInfo.TextSettings.FontColor := AValue;
end;

procedure TSkLabel.TCustomWordsItem.SetHeightMultiplier(const AValue: Single);
begin
  FTextSettingsInfo.TextSettings.HeightMultiplier := AValue;
end;

procedure TSkLabel.TCustomWordsItem.SetLetterSpacing(const AValue: Single);
begin
  FTextSettingsInfo.TextSettings.LetterSpacing := AValue;
end;

procedure TSkLabel.TCustomWordsItem.SetName(const AValue: string);
var
  LValue: string;
begin
  LValue := AValue.Trim;
  if FName <> LValue then
  begin
    if string.Compare(LValue, FName, [TCompareOption.coIgnoreCase]) <> 0 then
      CheckName(LValue, Words);
    FName := LValue;
    Change;
  end;
end;

procedure TSkLabel.TCustomWordsItem.SetStyledSettings(
  const AValue: TSkStyledSettings);
begin
  FTextSettingsInfo.StyledSettings := AValue;
end;

procedure TSkLabel.TCustomWordsItem.TextSettingsChange(ASender: TObject);
begin
  Change;
end;

function TSkLabel.TCustomWordsItem.UniqueName(const AName: string;
  const ACollection: TCollection): string;
var
  S: string;
  I, J, LIndex, LMaxIndex: Integer;
  LFound: Boolean;
  LOriginalName: string;

  procedure SeparateNameIndex(var S: string; var AIndex: Integer);
  var
    I, N: integer;
  begin
    AIndex := -1;
    I := S.Length - 1;
    N := 0;
    while (N <= 9) and (I >= 0) and S.Chars[I].IsDigit do
    begin
      Dec(I);
      Inc(N);
    end;
    if (I >= 0) and InRange(N, 1, 5) then
    begin
      AIndex := S.Substring(I + 1).ToInteger;
      S := S.Substring(0, I + 1);
    end;
  end;

begin
  LOriginalName := AName.Trim;
  Result := LOriginalName;
  if ACollection <> nil then
  begin
    SeparateNameIndex(Result, LIndex);
    LMaxIndex := -1;
    LFound := False;
    for I := 0 to ACollection.Count - 1 do
      if (ACollection.Items[I] <> Self) and (ACollection.Items[I] is TCustomWordsItem) then
      begin
        S := TCustomWordsItem(ACollection.Items[I]).Name;
        SeparateNameIndex(S, J);
        if string.Compare(S, Result, [TCompareOption.coIgnoreCase]) = 0 then
        begin
          LMaxIndex := Max(LMaxIndex, J);
          if (LIndex = J) then
            LFound := True;
        end;
      end;
    if LFound then
    begin
      LMaxIndex := Max(LMaxIndex + 1, 1);
      Result := Result + LMaxIndex.ToString;
    end
    else
      Result := LOriginalName;
  end;
end;

{ TSkLabel.TWordsCollection }

function TSkLabel.TWordsCollection.Add: TCustomWordsItem;
begin
  Result := TCustomWordsItem(inherited Add);
end;

function TSkLabel.TWordsCollection.Add(const ACaption: string;
  const AColor: TAlphaColor; const AFontSize: Single;
  const AFontWeight: TSkFontComponent.TSkFontWeight;
  const AFontSlant: TSkFontComponent.TSkFontSlant): TCustomWordsItem;
begin
  Result := Add;
  Result.BeginUpdate;
  try
    Result.Caption := ACaption;
    Result.Font.BeginUpdate;
    try
      Result.Font.Size := AFontSize;
      Result.Font.Weight := AFontWeight;
      Result.Font.Slant := AFontSlant;
    finally
      Result.Font.EndUpdate;
    end;
    Result.FontColor := AColor;
  finally
    Result.EndUpdate;
  end;
end;

function TSkLabel.TWordsCollection.AddOrSet(const AName, ACaption: string;
  const AFontColor: TAlphaColor; const AFont: TSkFontComponent;
  const AOnClick: TNotifyEvent; const ACursor: TCursor): TCustomWordsItem;
begin
  Result := ItemByName[AName];
  if not Assigned(Result) then
    Result := Add;
  Result.BeginUpdate;
  try
    if not AName.IsEmpty then
      Result.Name := AName;
    Result.Caption := ACaption;
    Result.Font := AFont;
    Result.FontColor := AFontColor;
    Result.OnClick := AOnClick;
    Result.Cursor := ACursor;
  finally
    Result.EndUpdate;
  end;
end;

constructor TSkLabel.TWordsCollection.Create(AOwner: TPersistent;
  AItemClass: TCustomWordsItemClass);
begin
  if not (AOwner is TSkLabel) then
    raise ESkLabel.Create('You can use only the inheritors of class "TSkLabel"');
  inherited Create(AOwner, AItemClass);
  FLabel := TSkLabel(AOwner);
end;

function TSkLabel.TWordsCollection.GetItem(AIndex: Integer): TCustomWordsItem;
begin
  Result := TCustomWordsItem(inherited GetItem(AIndex));
end;

function TSkLabel.TWordsCollection.GetItemByName(
  const AName: string): TCustomWordsItem;
var
  LIndex: Integer;
begin
  LIndex := IndexOf(AName);
  if LIndex = -1 then
    Result := nil
  else
    Result := Items[LIndex];
end;

function TSkLabel.TWordsCollection.IndexOf(const AName: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to Count - 1 do
    if string.Compare(AName, Items[I].Name, [TCompareOption.coIgnoreCase]) = 0 then
    begin
      Result := I;
      Break;
    end;
end;

function TSkLabel.TWordsCollection.Insert(AIndex: Integer): TCustomWordsItem;
begin
  Result := TCustomWordsItem(inherited Insert(AIndex));
end;

procedure TSkLabel.TWordsCollection.SetItem(AIndex: Integer;
  const AValue: TCustomWordsItem);
begin
  inherited SetItem(AIndex, AValue);
end;

procedure TSkLabel.TWordsCollection.Update(AItem: TCollectionItem);
begin
  inherited;
  if (FLabel <> nil) and not (csDestroying in FLabel.ComponentState) then
  begin
    if Assigned(FOnChange) then
      FOnChange(Self);
  end;
end;

{ TSkLabel }

function TSkLabel.CanAutoSize(var ANewWidth, ANewHeight: Integer): Boolean;
var
  LNewWidth: Single;
  LNewHeight: Single;
begin
  if not (csLoading in ComponentState) then
  begin
    LNewWidth := ANewWidth;
    LNewHeight := ANewHeight;
    GetFitSize(LNewWidth, LNewHeight);
    ANewWidth := Ceil(LNewWidth);
    ANewHeight := Ceil(LNewHeight);
  end;
  Result := True;
end;

procedure TSkLabel.Click;
var
  LClickedItem: TCustomWordsItem;
begin
  LClickedItem := GetWordsItemAtPosition(FClickedPosition.X, FClickedPosition.Y);
  if Assigned(LClickedItem) and (LClickedItem = GetWordsItemAtPosition(FPressedPosition.X, FPressedPosition.Y)) then
  begin
    TMessageManager.DefaultManager.SendMessage(Self, TItemClickedMessage.Create(LClickedItem));
    if Assigned(LClickedItem.OnClick) then
      LClickedItem.OnClick(FWordsMouseOver)
    else
      inherited;
  end
  else
    inherited;
end;

procedure TSkLabel.CMBiDiModeChanged(var AMessage: TMessage);
begin
  TextSettingsChanged(nil);
  inherited;
end;

procedure TSkLabel.CMControlChange(var AMessage: TMessage);
begin
  inherited;
  if Assigned(FTextSettingsInfo) then
    FTextSettingsInfo.Design := csDesigning in ComponentState;
end;

procedure TSkLabel.CMMouseEnter(var AMessage: TMessage);
begin
  FIsMouseOver := True;
  inherited;
end;

procedure TSkLabel.CMMouseLeave(var AMessage: TMessage);
begin
  FIsMouseOver := False;
  inherited;
  SetWordsMouseOver(nil);
end;

procedure TSkLabel.CMParentBiDiModeChanged(var AMessage: TMessage);
begin
  TextSettingsChanged(nil);
  inherited;
end;

constructor TSkLabel.Create(AOwner: TComponent);
begin
  inherited;
  AutoSize := True;
  FTextSettingsInfo := TSkTextSettingsInfo.Create(Self, nil);
  FTextSettingsInfo.Design := True;//csDesigning in ComponentState;
  FTextSettingsInfo.StyledSettings := [];
  FTextSettingsInfo.OnChange := TextSettingsChanged;
  FWords := TWordsCollection.Create(Self, TWordsItem);
  FWords.OnChange := WordsChange;
end;

procedure TSkLabel.DeleteParagraph;
begin
  FParagraph := nil;
  FParagraphStroked := nil;
  FParagraphBounds := TRectF.Empty;
  FParagraphLayoutWidth := 0;
end;

destructor TSkLabel.Destroy;
begin
  FTextSettingsInfo.Free;
  FWords.Free;
  inherited;
end;

procedure TSkLabel.Draw(const ACanvas: ISkCanvas; const ADest: TRectF;
  const AOpacity: Single);

  function CreateBackgroundPicture(const AParagraph: ISkParagraph): ISkPicture;
  var
    LPictureRecorder: ISkPictureRecorder;
    LCanvas: ISkCanvas;
    LPaint: ISkPaint;
    I: Integer;
    LTextEndIndex: Integer;
    LTextBox: TSkTextBox;
    LRects: TArray<TRectF>;
    LRectsColor: TArray<TAlphaColor>;
    LLastRect: TRectF;
    LLastColor: TAlphaColor;
  begin
    LPictureRecorder := TSkPictureRecorder.Create;
    LCanvas := LPictureRecorder.BeginRecording(ADest);
    LPaint := TSkPaint.Create;
    LPaint.AntiAlias := True;
    LTextEndIndex := 0;
    LRects := nil;
    for I := 0 to FWords.Count - 1 do
    begin
      Inc(LTextEndIndex, FWords[I].Caption.Length);
      if TAlphaColorRec(FWords[I].BackgroundColor).A = 0 then
        Continue;
      for LTextBox in AParagraph.GetRectsForRange(LTextEndIndex - FWords[I].Caption.Length, LTextEndIndex, TSkRectHeightStyle.Tight, TSkRectWidthStyle.Tight) do
      begin
        if LRects = nil then
        begin
          LRects := [LTextBox.Rect];
          LRectsColor := [FWords[I].BackgroundColor];
          Continue;
        end;
        LLastRect := LRects[High(LRects)];
        LLastColor := LRectsColor[High(LRectsColor)];
        if (LLastColor = FWords[I].BackgroundColor) and SameValue(LLastRect.Right, LTextBox.Rect.Left, 1) and
          (InRange(LTextBox.Rect.CenterPoint.Y, LLastRect.Top, LLastRect.Bottom) or
          InRange(LLastRect.CenterPoint.Y, LTextBox.Rect.Top, LTextBox.Rect.Bottom)) then
        begin
          LLastRect.Right := LTextBox.Rect.Right;
          LLastRect.Top := Min(LLastRect.Top, LTextBox.Rect.Top);
          LLastRect.Bottom := Max(LLastRect.Bottom, LTextBox.Rect.Bottom);
          LRects[High(LRects)] := LLastRect;
        end
        else
        begin
          LRects := LRects + [LTextBox.Rect];
          LRectsColor := LRectsColor + [FWords[I].BackgroundColor];
        end;
      end;
    end;
    for I := 0 to Length(LRects) - 1 do
    begin
      LPaint.Color := LRectsColor[I];
      LCanvas.DrawRoundRect(TRectF.Create(LRects[I].Round), 2 * ScaleFactor, 2 * ScaleFactor, LPaint);
    end;
    Result := LPictureRecorder.FinishRecording;
  end;

var
  LParagraph: ISkParagraph;
  LPositionY: Single;
begin
  LParagraph := Paragraph;
  if Assigned(LParagraph) then
  begin
    ParagraphLayout(ADest.Width);
    LPositionY := ADest.Top;
    case ResultingTextSettings.VertAlign of
      TSkTextVertAlign.Center: LPositionY := LPositionY + ((ADest.Height - ParagraphBounds.Height) / 2);
      TSkTextVertAlign.Leading: ;
      TSkTextVertAlign.Trailing: LPositionY := LPositionY + (ADest.Height - ParagraphBounds.Height);
    end;

    if SameValue(AOpacity, 1, TEpsilon.Position) then
      ACanvas.Save
    else
      ACanvas.SaveLayerAlpha(Round(AOpacity * 255));
    try
      ACanvas.ClipRect(ADest);
      ACanvas.Translate(Round(ADest.Left), Round(LPositionY));
      if FHasCustomBackground then
      begin
        if FBackgroundPicture = nil then
          FBackgroundPicture := CreateBackgroundPicture(LParagraph);
        ACanvas.DrawPicture(FBackgroundPicture);
      end;
      LParagraph.Paint(ACanvas, 0, 0);
      if Assigned(FParagraphStroked) then
        FParagraphStroked.Paint(ACanvas, 0, 0);
    finally
      ACanvas.Restore;
    end;
  end;
end;

function TSkLabel.GetCaption: string;
var
  I: Integer;
begin
  Result := '';
  if Assigned(FWords) and (FWords.Count > 0) then
    for I := 0 to FWords.Count - 1 do
      Result := Result + FWords[I].Caption;
end;

function TSkLabel.GetDefaultTextSettings: TSkTextSettings;
begin
  Result := FTextSettingsInfo.DefaultTextSettings;
end;

procedure TSkLabel.GetFitSize(var AWidth, AHeight: Single);

  function GetFitHeight: Single;
  begin
    if (akTop in Anchors) and (akBottom in Anchors) then
      Result := AHeight
    else
      Result := Ceil(ParagraphBounds.Height * ScaleFactor);
  end;

  function GetFitWidth: Single;
  begin
    if (akLeft in Anchors) and (akRight in Anchors) then
      Result := AWidth
    else
      Result := Ceil(ParagraphBounds.Width * ScaleFactor);
  end;

var
  LParagraph: ISkParagraph;
begin
  LParagraph := Paragraph;
  if Assigned(LParagraph) then
  begin
    if (akLeft in Anchors) and (akRight in Anchors) then
      ParagraphLayout(AWidth)
    else
      ParagraphLayout(High(Integer));
  end;
  try
    AWidth := GetFitWidth;
    AHeight := GetFitHeight;
  finally
    if Assigned(LParagraph) then
      ParagraphLayout(AWidth);
  end;
end;

function TSkLabel.GetParagraph: ISkParagraph;
type
  TDrawKind = (Fill, Stroke);
const
  SkTextAlign: array[TSkTextHorzAlign] of TSkTextAlign = (TSkTextAlign.Center, TSkTextAlign.Start, TSkTextAlign.Terminate, TSkTextAlign.Justify);
  SkFontSlant: array[TSkFontComponent.TSkFontSlant] of TSkFontSlant = (TSkFontSlant.Upright, TSkFontSlant.Italic, TSkFontSlant.Oblique);
  SkFontWeightValue: array[TSkFontComponent.TSkFontWeight] of Integer = (100, 200, 300, 350, 400, 500, 600, 700, 800, 900, 950);
  SkFontWidthValue: array[TSkFontComponent.TSkFontStretch] of Integer = (1, 2, 3, 4, 5, 6, 7, 8, 9);
var
  LHasTextStroked: Boolean;

  function GetFontFamilies(const AValue: string): TArray<string>;
  begin
    Result := AValue.Split([', ', ','], TStringSplitOptions.ExcludeEmpty);
  end;

  procedure SetTextStyleDecorations(var ATextStyle: ISkTextStyle;
    const ADecorations: TSkTextSettings.TDecorations;
    const ADrawKind: TDrawKind);
  var
    LPaint: ISkPaint;
  begin
    if ADecorations.Decorations <> [] then
    begin
      if ADecorations.Color = TAlphaColors.Null then
        ATextStyle.DecorationColor := ATextStyle.Color
      else
        ATextStyle.DecorationColor := ADecorations.Color;
      ATextStyle.Decorations := ADecorations.Decorations;
      ATextStyle.DecorationStyle := ADecorations.Style;
      ATextStyle.DecorationThickness := ADecorations.Thickness;
    end;
    if ADrawKind = TDrawKind.Stroke then
    begin
      if (ADecorations.StrokeColor <> TAlphaColors.Null) and not SameValue(ADecorations.Thickness, 0, TEpsilon.Position) then
      begin
        LPaint := TSkPaint.Create(TSkPaintStyle.Stroke);
        LPaint.Color := ADecorations.StrokeColor;
        LPaint.StrokeWidth := (ADecorations.Thickness / 2) * (ATextStyle.FontSize / 14);
        ATextStyle.SetForegroundColor(LPaint);
      end
      else
        ATextStyle.Color := TAlphaColors.Null;
    end
    else
      LHasTextStroked := LHasTextStroked or
        ((ADecorations.StrokeColor <> TAlphaColors.Null) and not SameValue(ADecorations.Thickness, 0, TEpsilon.Position));
  end;

  function CreateTextStyle(const AWordsItem: TCustomWordsItem;
    const ADefaultTextStyle: ISkTextStyle; const ADrawKind: TDrawKind): ISkTextStyle;
  begin
    Result := TSkTextStyle.Create;
    if TSkStyledSetting.FontColor in AWordsItem.StyledSettings then
      Result.Color := ResultingTextSettings.FontColor
    else
      Result.Color := AWordsItem.FontColor;
    if TSkStyledSetting.Family in AWordsItem.StyledSettings then
      Result.FontFamilies := ADefaultTextStyle.FontFamilies
    else
      Result.FontFamilies := GetFontFamilies(AWordsItem.Font.Families);
    if TSkStyledSetting.Size in AWordsItem.StyledSettings then
      Result.FontSize := ADefaultTextStyle.FontSize
    else
      Result.FontSize := AWordsItem.Font.Size;
    if TSkStyledSetting.Style in AWordsItem.StyledSettings then
      Result.FontStyle := ADefaultTextStyle.FontStyle
    else
      Result.FontStyle := TSkFontStyle.Create(SkFontWeightValue[AWordsItem.Font.Weight], SkFontWidthValue[AWordsItem.Font.Stretch], SkFontSlant[AWordsItem.Font.Slant]);
    if TSkStyledSetting.Other in AWordsItem.StyledSettings then
    begin
      Result.HeightMultiplier := ADefaultTextStyle.HeightMultiplier;
      SetTextStyleDecorations(Result, ResultingTextSettings.Decorations, ADrawKind);
      Result.LetterSpacing := ADefaultTextStyle.LetterSpacing;
    end
    else
    begin
      Result.HeightMultiplier := AWordsItem.HeightMultiplier;
      SetTextStyleDecorations(Result, AWordsItem.Decorations, ADrawKind);
      Result.LetterSpacing := AWordsItem.LetterSpacing;
    end;
  end;

  function CreateDefaultTextStyle(const ADrawKind: TDrawKind): ISkTextStyle;
  begin
    Result := TSkTextStyle.Create;
    Result.Color := ResultingTextSettings.FontColor;
    Result.FontFamilies := GetFontFamilies(ResultingTextSettings.Font.Families);
    Result.FontSize := ResultingTextSettings.Font.Size;
    Result.FontStyle := TSkFontStyle.Create(SkFontWeightValue[ResultingTextSettings.Font.Weight], SkFontWidthValue[ResultingTextSettings.Font.Stretch], SkFontSlant[ResultingTextSettings.Font.Slant]);
    Result.HeightMultiplier := ResultingTextSettings.HeightMultiplier;
    Result.LetterSpacing := ResultingTextSettings.LetterSpacing;
    SetTextStyleDecorations(Result, ResultingTextSettings.Decorations, ADrawKind);
  end;

  function CreateParagraphStyle(const ADefaultTextStyle: ISkTextStyle): ISkParagraphStyle;
  begin
    Result := TSkParagraphStyle.Create;
    if UseRightToLeftAlignment then
      Result.TextDirection := TSkTextDirection.RightToLeft;
    if ResultingTextSettings.Trimming in [TSkTextTrimming.Character, TSkTextTrimming.Word] then
      Result.Ellipsis := '...';
    if ResultingTextSettings.MaxLines = 0 then
      Result.MaxLines := High(Integer)
    else
      Result.MaxLines := ResultingTextSettings.MaxLines;
    Result.TextAlign := SkTextAlign[ResultingTextSettings.HorzAlign];
    Result.TextStyle := ADefaultTextStyle;
  end;

  // Temporary solution to fix an issue with Skia: https://bugs.chromium.org/p/skia/issues/detail?id=13117
  // SkParagraph has several issues with the #13 line break, so the best thing to do is replace it with #10 or a zero-widh character (#8203)
  function NormalizeParagraphText(const AText: string): string;
  begin
    Result := AText.Replace(#13#10, #8203#10).Replace(#13, #10);
  end;

  function CreateParagraph(const ADrawKind: TDrawKind): ISkParagraph;
  var
    LBuilder: ISkParagraphBuilder;
    LDefaultTextStyle: ISkTextStyle;
    LText: string;
    I: Integer;
  begin
    LDefaultTextStyle := CreateDefaultTextStyle(ADrawKind);
    LBuilder := TSkParagraphBuilder.Create(CreateParagraphStyle(LDefaultTextStyle), TSkTypefaceManager.Provider);

    for I := 0 to FWords.Count- 1 do
    begin
      if FWords[I].Caption = '' then
        Continue;
      if FWords[I].StyledSettings = AllStyledSettings then
        LBuilder.AddText(FWords[I].Caption)
      else
      begin
        LText := NormalizeParagraphText(FWords[I].Caption);
        if not LText.IsEmpty then
        begin
          LBuilder.PushStyle(CreateTextStyle(FWords[I], LDefaultTextStyle, ADrawKind));
          LBuilder.AddText(LText);
          LBuilder.Pop;
        end;
      end;
      FHasCustomBackground := FHasCustomBackground or (FWords[I].BackgroundColor <> TAlphaColors.Null);
    end;
    Result := LBuilder.Build;
  end;

begin
  if (FParagraph = nil) and (Caption <> '') then
  begin
    FBackgroundPicture := nil;
    FHasCustomBackground := False;
    LHasTextStroked := False;
    FParagraph := CreateParagraph(TDrawKind.Fill);
    if LHasTextStroked then
      FParagraphStroked := CreateParagraph(TDrawKind.Stroke);
    ParagraphLayout(Width);
  end;
  Result := FParagraph;
end;

function TSkLabel.GetParagraphBounds: TRectF;

  function CalculateParagraphBounds: TRectF;
  var
    LParagraph: ISkParagraph;
  begin
    LParagraph := Paragraph;
    if Assigned(LParagraph) then
      Result := RectF(0, 0, Ceil(LParagraph.MaxIntrinsicWidth), Ceil(LParagraph.Height))
    else
      Result := TRectF.Empty;
  end;

begin
  if FParagraphBounds.IsEmpty then
    FParagraphBounds := CalculateParagraphBounds;
  Result := FParagraphBounds;
end;

function TSkLabel.GetResultingTextSettings: TSkTextSettings;
begin
  Result := FTextSettingsInfo.ResultingTextSettings;
end;

function TSkLabel.GetTextSettings: TSkTextSettings;
begin
  Result := FTextSettingsInfo.TextSettings;
end;

function TSkLabel.GetTextSettingsClass: TSkTextSettingsInfo.TCustomTextSettingsClass;
begin
  Result := TSkTextSettingsInfo.TCustomTextSettings;
end;

function TSkLabel.GetWordsItemAtPosition(const AX,
  AY: Integer): TCustomWordsItem;

  // Remove inconsistencies such as area after a line break
  function IsInsideValidArea(const AParagraph: ISkParagraph; const ATextArea: TRectF; const APoint: TPointF): Boolean;
  var
    LGlyphTextBoxes: TArray<TSkTextBox>;
    LGlyphPosition: TSkPositionAffinity;
  begin
    LGlyphPosition := AParagraph.GetGlyphPositionAtCoordinate(APoint.X, APoint.Y);
    if LGlyphPosition.Affinity = TSkAffinity.Downstream then
      Result := True
    else if LGlyphPosition.Position >= 0 then
    begin
      LGlyphTextBoxes := AParagraph.GetRectsForRange(LGlyphPosition.Position, LGlyphPosition.Position + 1, TSkRectHeightStyle.Max, TSkRectWidthStyle.Tight);
      Result := (LGlyphTextBoxes <> nil) and
        ((LGlyphTextBoxes[0].Rect.CenterPoint.Distance(APoint) < (LGlyphTextBoxes[0].Rect.Width + LGlyphTextBoxes[0].Rect.Height) / 2) or
        ATextArea.Contains(LGlyphTextBoxes[0].Rect.CenterPoint));
    end
    else
      Result := False;
  end;

var
  I, J: Integer;
  LTextIndex: Integer;
  LTextBoxes: TArray<TSkTextBox>;
  LParagraph: ISkParagraph;
  LParagraphPoint: TPointF;
begin
  Result := nil;
  LParagraph := Paragraph;
  if Assigned(LParagraph) then
  begin
    case ResultingTextSettings.VertAlign of
      TSkTextVertAlign.Center: LParagraphPoint := PointF(AX, AY - (Height - ParagraphBounds.Height) / 2);
      TSkTextVertAlign.Trailing: LParagraphPoint := PointF(AX, AY - Height - ParagraphBounds.Height);
    else
      LParagraphPoint := PointF(AX, AY);
    end;
    LTextIndex := 0;
    for I := 0 to FWords.Count - 1 do
    begin
      if FWords[I].Caption.Length = 0 then
        Continue;
      LTextBoxes := LParagraph.GetRectsForRange(LTextIndex, LTextIndex + FWords[I].Caption.Length, TSkRectHeightStyle.Max, TSkRectWidthStyle.Tight);
      for J := 0 to Length(LTextBoxes) - 1 do
      begin
        if LTextBoxes[J].Rect.Contains(LParagraphPoint) then
        begin
          if IsInsideValidArea(LParagraph, LTextBoxes[J].Rect, LParagraphPoint) then
            Result := FWords[I];
          Break;
        end;
      end;
      if Assigned(Result) then
        Break;
      Inc(LTextIndex, FWords[I].Caption.Length);
    end;
  end;
end;

function TSkLabel.HasFitSizeChanged: Boolean;
var
  LNewWidth: Single;
  LNewHeight: Single;
begin
  LNewWidth := Width;
  LNewHeight := Height;
  GetFitSize(LNewWidth, LNewHeight);
  Result := (not SameValue(LNewWidth, Width, TEpsilon.Position)) or (not SameValue(LNewHeight, Height, TEpsilon.Position));
end;

procedure TSkLabel.Loaded;
begin
  inherited;
  if AutoSize and HasFitSizeChanged then
    SetBounds(Left, Top, Width, Height);
end;

procedure TSkLabel.MouseDown(AButton: TMouseButton; AShift: TShiftState; AX,
  AY: Integer);
begin
  if AButton = TMouseButton.mbLeft then
    FPressedPosition := Point(AX, AY);
  inherited;
end;

procedure TSkLabel.ParagraphLayout(const AWidth: Single);
var
  LParagraph: ISkParagraph;
begin
  if not SameValue(FParagraphLayoutWidth, AWidth, TEpsilon.Position) then
  begin
    LParagraph := Paragraph;
    if Assigned(LParagraph) then
    begin
      LParagraph.Layout(AWidth);
      if Assigned(FParagraphStroked) then
        FParagraphStroked.Layout(AWidth);
      FParagraphLayoutWidth := AWidth;
      FParagraphBounds := TRectF.Empty;
      FBackgroundPicture := nil;
    end;
  end;
end;

procedure TSkLabel.SetCaption(const AValue: string);
begin
  if Assigned(FWords) then
  begin
    FWords.BeginUpdate;
    try
      if FWords.Count = 1 then
        FWords[0].Caption := AValue
      else
      begin
        FWords.Clear;
        FWords.Add.Caption := AValue;
      end;
    finally
      FWords.EndUpdate;
    end;
  end;
end;

procedure TSkLabel.SetName(const AValue: TComponentName);
var
  LChangeCaption: Boolean;
begin
  LChangeCaption := not (csLoading in ComponentState) and (Name = Caption) and
    ((Owner = nil) or not (csLoading in TComponent(Owner).ComponentState));
  inherited SetName(AValue);
  if LChangeCaption then
    Caption := AValue;
end;

procedure TSkLabel.SetTextSettings(const AValue: TSkTextSettings);
begin
  FTextSettingsInfo.TextSettings := AValue;
end;

procedure TSkLabel.SetWords(const AValue: TWordsCollection);
begin
  FWords.Assign(AValue);
end;

procedure TSkLabel.SetWordsMouseOver(const AValue: TCustomWordsItem);
begin
  if FWordsMouseOver <> AValue then
  begin
    FWordsMouseOver := AValue;
    if not (csDesigning in ComponentState) and IsMouseOver then
    begin
      if Assigned(FWordsMouseOver) and (FWordsMouseOver.Cursor <> crDefault) then
        Cursor := FWordsMouseOver.Cursor
      else
        Cursor := crDefault;
    end;
  end
  else if Assigned(FWordsMouseOver) and (FWordsMouseOver.Cursor <> crDefault) then
    Cursor := FWordsMouseOver.Cursor
  else
    Cursor := crDefault;
end;

procedure TSkLabel.TextSettingsChanged(AValue: TObject);
begin
  DeleteParagraph;
  if not (csLoading in ComponentState) then
  begin
    if AutoSize and HasFitSizeChanged then
      SetBounds(Left, Top, Width, Height)
    else
      Redraw;
  end;
end;

type
  TControlAccess = class(TControl);

function TSkLabel.UseRightToLeftAlignment: Boolean;

  function GetParentedBiDiMode: TBiDiMode;
  var
    LControl: TControl;
  begin
    LControl := Self;
    repeat
      Result := LControl.BiDiMode;
      if not TControlAccess(LControl).ParentBiDiMode then
        Break;
      LControl := LControl.Parent;
    until LControl = nil;
  end;

begin
  Result := SysLocale.MiddleEast and (GetParentedBiDiMode = bdRightToLeft);
end;

procedure TSkLabel.WMLButtonUp(var AMessage: TWMLButtonUp);
begin
  FClickedPosition := Point(AMessage.XPos, AMessage.YPos);
  inherited;
end;

procedure TSkLabel.WMMouseMove(var AMessage: TWMMouseMove);
begin
  if FHasCustomCursor then
    SetWordsMouseOver(GetWordsItemAtPosition(AMessage.XPos, AMessage.YPos));
  inherited;
end;

procedure TSkLabel.WordsChange(ASender: TObject);
var
  I: Integer;
begin
  FHasCustomCursor := False;
  for I := 0 to FWords.Count - 1 do
  begin
    if FWords[I].Cursor <> crDefault then
    begin
      FHasCustomCursor := True;
      Break;
    end;
  end;
  if FWords.Count = 0 then
    FWords.Add
  else
    TextSettingsChanged(nil);
end;

{ TSkTypefaceManager }

class constructor TSkTypefaceManager.Create;
begin
  FProvider := TSkTypefaceFontProvider.Create;
end;

class procedure TSkTypefaceManager.RegisterTypeface(const AFileName: string);
begin
  FProvider.RegisterTypeface(TSkTypeFace.MakeFromFile(AFileName));
end;

class procedure TSkTypefaceManager.RegisterTypeface(const AStream: TStream);
begin
  FProvider.RegisterTypeface(TSkTypeFace.MakeFromStream(AStream));
end;

{ TSkGraphic }

procedure TSkGraphic.Assign(ASource: TPersistent);
begin
  if ASource is TSkGraphic then
  begin
    if TObject(FImage) <> TObject(TSkGraphic(ASource).FImage) then
    begin
      FImage := TSkGraphic(ASource).FImage;
      Changed(Self);
    end;
  end
  else
    inherited;
end;

{$IF CompilerVersion >= 32}
class function TSkGraphic.CanLoadFromStream(AStream: TStream): Boolean;
const
  SupportedFormats = [TSkEncodedImageFormat.WEBP, TSkEncodedImageFormat.WBMP, TSkEncodedImageFormat.DNG];
var
  LCodec: ISkCodec;
begin
  LCodec := TSkCodec.MakeFromStream(AStream);
  Result := Assigned(LCodec) and (LCodec.EncodedImageFormat in SupportedFormats);
end;
{$ENDIF}

procedure TSkGraphic.Changed(ASender: TObject);
begin
  FreeAndNil(FBuffer);
  inherited;
end;

destructor TSkGraphic.Destroy;
begin
  FBuffer.Free;
  inherited;
end;

procedure TSkGraphic.Draw(ACanvas: TCanvas; const ARect: TRect);
begin
  DrawTransparent(ACanvas, ARect, High(Byte));
end;

procedure TSkGraphic.DrawTransparent(ACanvas: TCanvas; const ARect: TRect;
  AOpacity: Byte);
var
  LBitmap: TBitmap;
begin
  LBitmap := GetBuffer(ARect.Size, AOpacity);
  if Assigned(LBitmap) then
    ACanvas.Draw(ARect.Left, ARect.Top, LBitmap);
end;

function TSkGraphic.Equals(AGraphic: TGraphic): Boolean;

  function Equals(const ALeft, ARight: ISkPixmap): Boolean;
  var
    I: Integer;
  begin
    if ALeft.ImageInfo <> ARight.ImageInfo then
      Exit(False);
    if (ALeft.RowBytes = ARight.RowBytes) and (ALeft.RowBytes = ALeft.ImageInfo.MinRowBytes) then
      Result := CompareMem(ALeft.Pixels, ARight.Pixels, ALeft.RowBytes * NativeUInt(ALeft.Height))
    else
    begin
      Result := True;
      for I := 0 to ALeft.Height - 1 do
        if not CompareMem(ALeft.PixelAddr[0, I], ARight.PixelAddr[0, I], ALeft.ImageInfo.BytesPerPixel * ALeft.Width) then
          Exit(False);
    end;
  end;

var
  LPixmap: ISkPixmap;
  LPixmap2: ISkPixmap;
begin
  if AGraphic is TSkGraphic then
  begin
    Result := (Empty and AGraphic.Empty) or
      (FImage.ReadPixels(LPixmap) and TSkGraphic(AGraphic).FImage.ReadPixels(LPixmap2) and Equals(LPixmap, LPixmap2));
  end
  else
    Result := inherited;
end;

function TSkGraphic.GetBuffer(const ASize: TSize; const AOpacity: Byte): TBitmap;
begin
  if Empty or (ASize.Width <= 0) or (ASize.Height <= 0) or (AOpacity = 0) then
    Exit(nil);
  if Assigned(FBuffer) and (ASize.Width = FBuffer.Width) and (ASize.Height = FBuffer.Height) and (AOpacity = FBufferOpacity) then
    Exit(FBuffer);
  if not Assigned(FBuffer) then
  begin
    FBuffer := TBitmap.Create;
    FBuffer.PixelFormat := TPixelFormat.pf32bit;
    FBuffer.AlphaFormat := TAlphaFormat.afPremultiplied;
  end;
  FBuffer.SetSize(ASize.Width, ASize.Height);
  FBuffer.SkiaDraw(
    procedure(const ACanvas: ISkCanvas)
    var
      LPaint: ISkPaint;
    begin
      if AOpacity = High(AOpacity) then
        LPaint := nil
      else
      begin
        LPaint := TSkPaint.Create;
        LPaint.Alpha := AOpacity;
      end;
      if (FBuffer.Width = Width) and (FBuffer.Height = Height) then
        ACanvas.DrawImage(FImage, 0, 0, LPaint)
      else
      begin
        ACanvas.Scale(FBuffer.Width / Width, FBuffer.Height / Height);
        ACanvas.DrawImage(FImage, 0, 0, TSkSamplingOptions.Medium, LPaint);
      end;
    end);
  FBufferOpacity := AOpacity;
  Result := FBuffer;
end;

function TSkGraphic.GetEmpty: Boolean;
begin
  Result := (not Assigned(FImage)) or (FImage.Width <= 0) or (FImage.Height <= 0);
end;

function TSkGraphic.GetHeight: Integer;
begin
  if Assigned(FImage) then
    Result := FImage.Height
  else
    Result := 0;
end;

function TSkGraphic.GetSupportsPartialTransparency: Boolean;
begin
  Result := True;
end;

function TSkGraphic.GetWidth: Integer;
begin
  if Assigned(FImage) then
    Result := FImage.Width
  else
    Result := 0;
end;

procedure TSkGraphic.LoadFromClipboardFormat(AFormat: Word; AData: THandle;
  APalette: HPALETTE);
begin
end;

procedure TSkGraphic.LoadFromStream(AStream: TStream);
begin
  FImage := TSkImage.MakeFromEncodedStream(AStream);
  Changed(Self);
end;

procedure TSkGraphic.SaveToClipboardFormat(var AFormat: Word;
  var AData: THandle; var APalette: HPALETTE);
begin
end;

procedure TSkGraphic.SaveToFile(const AFileName: string);
begin
  if AFilename.EndsText(AFileName, '.jpg') or AFilename.EndsText(AFileName, '.jpeg') then
    FImage.EncodeToFile(AFileName, TSkEncodedImageFormat.JPEG)
  else if AFilename.EndsText(AFileName, '.webp') then
    FImage.EncodeToFile(AFileName, TSkEncodedImageFormat.WEBP)
  else
    FImage.EncodeToFile(AFileName);
end;

procedure TSkGraphic.SaveToStream(AStream: TStream);
begin
  FImage.EncodeToStream(AStream);
end;

procedure TSkGraphic.SetHeight(AValue: Integer);
begin
  SetSize(Width, AValue);
end;

procedure TSkGraphic.SetSize(AWidth, AHeight: Integer);
var
  LSurface: ISkSurface;
  LPixmap: ISkPixmap;
begin
  if (Width <> AWidth) or (Height <> AHeight) then
  begin
    if Assigned(FImage) then
    begin
      FImage.ScalePixels(LPixmap, TSkSamplingOptions.Medium);
      FImage := TSkImage.MakeRasterCopy(LPixmap);
    end
    else
    begin
      LSurface := TSkSurface.MakeRaster(AWidth, AHeight);
      LSurface.Canvas.Clear(TAlphaColors.Null);
      FImage := LSurface.MakeImageSnapshot;
    end;
    Changed(Self);
  end;
end;

procedure TSkGraphic.SetWidth(AValue: Integer);
begin
  SetSize(AValue, Height);
end;

{ TSkSvgGraphic }

procedure TSkSvgGraphic.Assign(ASource: TPersistent);
begin
  if ASource is TSkSvgGraphic then
    FSvgBrush.Assign(TSkSvgGraphic(ASource).FSvgBrush)
  else
    inherited;
end;

procedure TSkSvgGraphic.Changed(ASender: TObject);
begin
  FreeAndNil(FBuffer);
  inherited;
end;

constructor TSkSvgGraphic.Create;
begin
  inherited;
  FSvgBrush := TSkSvgBrush.Create;
  FSvgBrush.WrapMode := TSkSvgWrapMode.Stretch;
  FSvgBrush.OnChanged := Changed;
end;

destructor TSkSvgGraphic.Destroy;
begin
  FBuffer.Free;
  FSvgBrush.Free;
  inherited;
end;

procedure TSkSvgGraphic.Draw(ACanvas: TCanvas; const ARect: TRect);
begin
  DrawTransparent(ACanvas, ARect, High(Byte));
end;

procedure TSkSvgGraphic.DrawTransparent(ACanvas: TCanvas; const ARect: TRect;
  AOpacity: Byte);
var
  LBitmap: TBitmap;
begin
  LBitmap := GetBuffer(ARect.Size, AOpacity);
  if Assigned(LBitmap) then
    ACanvas.Draw(ARect.Left, ARect.Top, LBitmap);
end;

function TSkSvgGraphic.Equals(AGraphic: TGraphic): Boolean;
begin
  Result := (AGraphic is TSkSvgGraphic) and (FSvgBrush.Source = TSkSvgGraphic(AGraphic).FSvgBrush.Source);
end;

function TSkSvgGraphic.GetBuffer(const ASize: TSize;
  const AOpacity: Byte): TBitmap;
begin
  if Empty or (ASize.Width <= 0) or (ASize.Height <= 0) or (AOpacity = 0) then
    Exit(nil);
  if Assigned(FBuffer) and (ASize.Width = FBuffer.Width) and (ASize.Height = FBuffer.Height) and (AOpacity = FBufferOpacity) then
    Exit(FBuffer);
  if not Assigned(FBuffer) then
  begin
    FBuffer := TBitmap.Create;
    FBuffer.PixelFormat := TPixelFormat.pf32bit;
    FBuffer.AlphaFormat := TAlphaFormat.afPremultiplied;
  end;
  FBuffer.SetSize(ASize.Width, ASize.Height);
  FBuffer.SkiaDraw(
    procedure(const ACanvas: ISkCanvas)
    begin
      FSvgBrush.Render(ACanvas, RectF(0, 0, FBuffer.Width, FBuffer.Height), AOpacity / 255);
    end);
  FBufferOpacity := AOpacity;
  Result := FBuffer;
end;

function TSkSvgGraphic.GetEmpty: Boolean;
begin
  Result := FSvgBrush.Source = '';
end;

function TSkSvgGraphic.GetHeight: Integer;
begin
  Result := Round(FSvgBrush.OriginalSize.Height);
end;

function TSkSvgGraphic.GetSupportsPartialTransparency: Boolean;
begin
  Result := True;
end;

function TSkSvgGraphic.GetWidth: Integer;
begin
  Result := Round(FSvgBrush.OriginalSize.Width);
end;

procedure TSkSvgGraphic.LoadFromClipboardFormat(AFormat: Word; AData: THandle;
  APalette: HPALETTE);
begin
end;

procedure TSkSvgGraphic.LoadFromStream(AStream: TStream);
var
  LBytes: TBytes;
begin
  SetLength(LBytes, AStream.Size - AStream.Position);
  if Length(LBytes) > 0 then
  begin
    AStream.ReadBuffer(LBytes, Length(LBytes));
    FSvgBrush.Source := TEncoding.UTF8.GetString(LBytes);
  end
  else
    FSvgBrush.Source := '';
end;

procedure TSkSvgGraphic.SaveToClipboardFormat(var AFormat: Word;
  var AData: THandle; var APalette: HPALETTE);
begin
end;

procedure TSkSvgGraphic.SaveToFile(const AFileName: string);
begin
  TFile.WriteAllText(AFileName, FSvgBrush.Source);
end;

procedure TSkSvgGraphic.SaveToStream(AStream: TStream);
var
  LBytes: TBytes;
begin
  if FSvgBrush.Source <> '' then
  begin
    LBytes := TEncoding.UTF8.GetBytes(FSvgBrush.Source);
    AStream.WriteBuffer(LBytes, Length(LBytes));
  end;
end;

procedure TSkSvgGraphic.SetHeight(AValue: Integer);
begin
end;

procedure TSkSvgGraphic.SetWidth(AValue: Integer);
begin
end;

{ Register }

procedure Register;
begin
  RegisterComponents('Skia', [TSkAnimatedImage, TSkAnimatedPaintBox, TSkLabel, TSkPaintBox, TSkSvg]);
end;

initialization
  TSkAnimatedImage.RegisterCodec(TSkLottieAnimationCodec);
  TSkAnimatedImage.RegisterCodec(TSkDefaultAnimationCodec);
  TPicture.RegisterFileFormat('svg', 'Scalable Vector Graphics', TSkSvgGraphic);
  TPicture.RegisterFileFormat('webp', 'WebP Images', TSkGraphic);
  TPicture.RegisterFileFormat('wbmp', 'WBMP Images', TSkGraphic);
  TPicture.RegisterFileFormat('arw', 'Raw Sony', TSkGraphic);
  TPicture.RegisterFileFormat('cr2', 'Raw Canon', TSkGraphic);
  TPicture.RegisterFileFormat('dng', 'Raw Adobe DNG Digital Negative', TSkGraphic);
  TPicture.RegisterFileFormat('nef', 'Raw Nikon', TSkGraphic);
  TPicture.RegisterFileFormat('nrw', 'Raw Nikon', TSkGraphic);
  TPicture.RegisterFileFormat('orf', 'Raw Olympus ORF', TSkGraphic);
  TPicture.RegisterFileFormat('raf', 'Raw Fujifilm RAF', TSkGraphic);
  TPicture.RegisterFileFormat('rw2', 'Raw Panasonic', TSkGraphic);
  TPicture.RegisterFileFormat('pef', 'Raw Pentax PEF', TSkGraphic);
  TPicture.RegisterFileFormat('srw', 'Raw Samsung SRW', TSkGraphic);
  TSkCustomAnimation.FrameRate := TSkCustomAnimation.DefaultFrameRate;
finalization
  TPicture.UnregisterGraphicClass(TSkGraphic);
  TPicture.UnregisterGraphicClass(TSkSvgGraphic);
end.

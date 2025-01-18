{************************************************************************}
{                                                                        }
{                              Skia4Delphi                               }
{                                                                        }
{ Copyright (c) 2021-2025 Skia4Delphi Project.                           }
{                                                                        }
{ Use of this source code is governed by the MIT license that can be     }
{ found in the LICENSE file.                                             }
{                                                                        }
{************************************************************************}
unit FMX.Skia;

interface

{$SCOPEDENUMS ON}

uses
  { Delphi }
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Math,
  System.Messaging,
  System.Generics.Collections,
  FMX.Types,
  FMX.Graphics,
  FMX.Controls,
  FMX.ActnList,

  { Skia }
  System.Skia;

const
  {$IF CompilerVersion < 33}
  SkSupportedPlatformsMask = pidWin32 or pidWin64;
  {$ELSEIF CompilerVersion < 35}
  SkSupportedPlatformsMask = pidWin32 or pidWin64 or pidAndroid32Arm or pidAndroid64Arm;
  {$ELSE}
  SkSupportedPlatformsMask = pidAllPlatforms;
  {$ENDIF}

type
  ESkFMX              = class(Exception);
  ESkBitmapHelper     = class(ESkFMX);
  ESkPersistentData   = class(ESkFMX);
  ESkTextSettingsInfo = class(ESkFMX);
  ESkLabel            = class(ESkFMX);

  TSkDrawProc = reference to procedure(const ACanvas: ISkCanvas);

  { TSkBitmapHelper }

  TSkBitmapHelper = class helper for TBitmap
  public
    constructor CreateFromSkImage(const AImage: ISkImage);
    procedure SkiaDraw(const AProc: TSkDrawProc; const AStartClean: Boolean = True);
    function ToSkImage: ISkImage;
  end;

  { TSkPathDataHelper }

  TSkPathDataHelper = class helper for TPathData
  public
    constructor CreateFromSkPath(const AValue: ISkPath);
    procedure AddSkPath(const AValue: ISkPath);
    procedure FromSkPath(const AValue: ISkPath); deprecated 'Use TPathData.CreateFromSkPath instead';
    function ToSkPath: ISkPath;
  end;

  { TSkPersistent }

  TSkPersistent = class(TPersistent)
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
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
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
  end;

  TSkDrawEvent = procedure(ASender: TObject; const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single) of object;
  TSkDrawCacheKind = (Never, Raster, Always);

  { TSkCustomControl }

  TSkCustomControl = class abstract(TControl)
  strict private
    FBuffer: TBitmap;
    FDrawCached: Boolean;
    FDrawCacheKind: TSkDrawCacheKind;
    FOnDraw: TSkDrawEvent;
    procedure SetDrawCacheKind(const AValue: TSkDrawCacheKind);
    procedure SetOnDraw(const AValue: TSkDrawEvent);
  strict protected
    procedure Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single); virtual;
    function NeedsRedraw: Boolean; virtual;
    procedure Paint; override; final;
    property DrawCacheKind: TSkDrawCacheKind read FDrawCacheKind write SetDrawCacheKind default TSkDrawCacheKind.Raster;
    property OnDraw: TSkDrawEvent read FOnDraw write SetOnDraw;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Redraw;
  published
    property Align;
    property Anchors;
    property ClipChildren default False;
    property ClipParent default False;
    property Cursor default crDefault;
    property DragMode default TDragMode.dmManual;
    property Enabled default True;
    property EnableDragHighlight default True;
    property Height;
    property Hint;
    property HitTest default False;
    property Locked default False;
    property Margins;
    property Opacity;
    property Padding;
    {$IF CompilerVersion >= 30}
    property ParentShowHint;
    {$ENDIF}
    property PopupMenu;
    property Position;
    property RotationAngle;
    property RotationCenter;
    property Scale;
    property ShowHint;
    property Size;
    property Visible default True;
    property Width;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragEnd;
    property OnDragEnter;
    property OnDragLeave;
    property OnDragOver;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnPainting;
    property OnResize;
    {$IF CompilerVersion >= 32}
    property OnResized;
    {$ENDIF}
  end;

  { TSkStyledControl }

  TSkStyledControl = class abstract(TStyledControl)
  strict private
    FBuffer: TBitmap;
    FDrawCached: Boolean;
    FDrawCacheKind: TSkDrawCacheKind;
    FOnDraw: TSkDrawEvent;
    procedure SetDrawCacheKind(const AValue: TSkDrawCacheKind);
    procedure SetOnDraw(const AValue: TSkDrawEvent);
  strict protected
    procedure Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single); virtual;
    function NeedsRedraw: Boolean; virtual;
    procedure Paint; override; final;
    property DrawCacheKind: TSkDrawCacheKind read FDrawCacheKind write SetDrawCacheKind default TSkDrawCacheKind.Raster;
    property OnDraw: TSkDrawEvent read FOnDraw write SetOnDraw;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Redraw;
  end;

  { TSkPaintBox }

  [ComponentPlatforms(SkSupportedPlatformsMask)]
  TSkPaintBox = class(TSkCustomControl)
  public
    property DrawCacheKind;
  published
    property OnDraw;
  end;

  TSkSvgSource = type string;
  TSkSvgWrapMode = (Default, Fit, FitCrop, Original, OriginalCenter, Place, Stretch, Tile);

  { TSkSvgBrush }

  TSkSvgBrush = class(TPersistent)
  strict private const
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

  [ComponentPlatforms(SkSupportedPlatformsMask)]
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

  { TSkCustomAnimation }

  TSkCustomAnimation = class(TSkPersistent)
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
  strict private type
    TProcess = class
    strict private
      // Unsafe referece for TSkAnimation in list
      FAniList: TList<Pointer>;
      FAniProcessingList: TList<Pointer>;
      [unsafe] FAniRoot: TSkCustomAnimation;
      FAnimation: TFmxObject;
      FMainFormChangedMessageId: {$IF CompilerVersion >= 36}TMessageSubscriptionId{$ELSE}Integer{$ENDIF};
      FTime: Double;
      FTimerService: IFMXTimerService;
      procedure DoAdd(const AAnimation: TSkCustomAnimation);
      procedure DoRemove(const AAnimation: TSkCustomAnimation);
      procedure DoRootChanged(const AAnimation: TSkCustomAnimation);
      procedure MainFormChangeHandler(const ASender: TObject; const AMessage: TMessage);
      procedure OnProcess(ASender: TObject);
      procedure TryFindRoot;
    strict private
      class var FProcess: TProcess;
      class destructor Destroy;
    public
      constructor Create;
      destructor Destroy; override;
      class procedure Add(const AAnimation: TSkCustomAnimation); static;
      class procedure Remove(const AAnimation: TSkCustomAnimation); static;
      class procedure RootChanged(const AAnimation: TSkCustomAnimation); static;
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
    function GetRoot: IRoot;
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
    property Root: IRoot read GetRoot;
    property SavedProgress: Double read FSavedProgress write FSavedProgress;
  protected
    procedure BeforePaint;
    procedure DoAssign(ASource: TPersistent); override;
    procedure DoChanged; override;
    procedure DoFinish; virtual; abstract;
    procedure DoProcess; virtual; abstract;
    procedure DoStart; virtual; abstract;
    function GetDuration: Double;
    procedure RootChanged;
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

  TSkCustomAnimatedControl = class abstract(TSkCustomControl)
  protected type
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
    FSuccessRedraw: Boolean;
    procedure CheckDuration;
    function GetAbsoluteVisible: Boolean;
    procedure SetOnAnimationDraw(const AValue: TSkAnimationDrawEvent);
  strict protected
    FAnimation: TAnimationBase;
    procedure AncestorVisibleChanged(const AVisible: Boolean); override;
    function CanRunAnimation: Boolean; virtual;
    procedure CheckAnimation;
    function CreateAnimation: TAnimationBase; virtual; abstract;
    procedure DoAnimationChanged; virtual;
    procedure DoAnimationFinish; virtual;
    procedure DoAnimationProcess; virtual;
    procedure DoAnimationStart; virtual;
    procedure DoRootChanged; override;
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
    procedure SetNewScene(AScene: IScene); override;
  end;

  { TSkAnimatedPaintBox }

  [ComponentPlatforms(SkSupportedPlatformsMask)]
  TSkAnimatedPaintBox = class(TSkCustomAnimatedControl)
  public type
    { TAnimation }

    TAnimation = class(TAnimationBase)
    protected const
      DefaultDuration = 1;
    strict private
      function IsDurationStored: Boolean;
    strict protected
      procedure DoAssign(ASource: TPersistent); override;
    public
      constructor Create(const AOwner: TFmxObject);
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

  [ComponentPlatforms(SkSupportedPlatformsMask)]
  TSkAnimatedImage = class(TSkCustomAnimatedControl)
  public type
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
    public type
      TChangeProc = procedure of object;
    strict private
      FData: TBytes;
      FOnChange: TChangeProc;
      procedure SetData(const AValue: TBytes);
    public
      constructor Create(const AOnChange: TChangeProc);
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
    strict private
      FQuality: TCanvasQuality;
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
      property Quality: TCanvasQuality read FQuality write FQuality;
      property Size: TSizeF read GetSize;
    end;

    TAnimationCodecClass = class of TAnimationCodec;
  strict private class var
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
    procedure WriteData(AStream: TStream);
  strict protected
    function CreateAnimation: TSkCustomAnimatedControl.TAnimationBase; override;
    procedure DefineProperties(AFiler: TFiler); override;
    procedure Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single); override;
    procedure RenderFrame(const ACanvas: ISkCanvas; const ADest: TRectF; const AProgress: Double; const AOpacity: Single); override;
    procedure SourceChange; virtual;
    property Codec: TAnimationCodec read FCodec;
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

  {$IF CompilerVersion < 31}
  TFontWeight = (Thin, UltraLight, Light, SemiLight, Regular, Medium, Semibold, Bold, UltraBold, Black, UltraBlack);
  TFontSlant = (Regular, Italic, Oblique);
  TFontStretch = (UltraCondensed, ExtraCondensed, Condensed, SemiCondensed, Regular, SemiExpanded, Expanded, ExtraExpanded, UltraExpanded);
  {$ENDIF}

  { TSkFontComponent }

  TSkFontComponent = class(TSkPersistent)
  strict protected const
    DefaultSize = 14;
    DefaultSlant = TFontSlant.Regular;
    DefaultStretch = TFontStretch.Regular;
    DefaultWeight = TFontWeight.Regular;
  strict private
    FFamilies: string;
    FSize: Single;
    FSlant: TFontSlant;
    FStretch: TFontStretch;
    FWeight: TFontWeight;
    procedure SetFamilies(const AValue: string);
    procedure SetSize(const AValue: Single);
    procedure SetSlant(const AValue: TFontSlant);
    procedure SetStretch(const AValue: TFontStretch);
    procedure SetWeight(const AValue: TFontWeight);
  strict protected
    procedure AssignTo(ADest: TPersistent); override;
    function DefaultFamilies: string; virtual;
    procedure DoAssign(ASource: TPersistent); override;
    function IsFamiliesStored: Boolean; virtual;
    function IsSizeStored: Boolean; virtual;
  public
    constructor Create;
    function Equals(AObject: TObject): Boolean; override;
    property OnChange;
  published
    property Families: string read FFamilies write SetFamilies stored IsFamiliesStored;
    property Size: Single read FSize write SetSize stored IsSizeStored;
    property Slant: TFontSlant read FSlant write SetSlant default DefaultSlant;
    property Stretch: TFontStretch read FStretch write SetStretch default DefaultStretch;
    property Weight: TFontWeight read FWeight write SetWeight default DefaultWeight;
  end;

  TSkTextHorzAlign = (Center, Leading, Trailing, Justify);

  { TSkTextSettings }

  TSkTextSettings = class(TSkPersistent)
  public type
    { TDecorations }

    TDecorations = class(TSkPersistent)
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
  strict protected const
    DefaultFontColor = TAlphaColors.Black;
    DefaultHeightMultiplier = 0;
    DefaultHorzAlign = TSkTextHorzAlign.Leading;
    DefaultLetterSpacing = 0;
    DefaultMaxLines = 1;
    DefaultTrimming = TTextTrimming.Word;
    DefaultVertAlign = TTextAlign.Center;
  strict private
    FDecorations: TDecorations;
    FFont: TSkFontComponent;
    FFontColor: TAlphaColor;
    FHeightMultiplier: Single;
    FHorzAlign: TSkTextHorzAlign;
    FLetterSpacing: Single;
    FMaxLines: NativeUInt;
    [unsafe] FOwner: TPersistent;
    FTrimming: TTextTrimming;
    FVertAlign: TTextAlign;
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
    procedure SetTrimming(const AValue: TTextTrimming);
    procedure SetVertAlign(const AValue: TTextAlign);
  strict protected
    function CreateFont: TSkFontComponent; virtual;
    procedure DoAssign(ASource: TPersistent); override;
    procedure DoAssignNotStyled(const ATextSettings: TSkTextSettings; const AStyledSettings: TStyledSettings); virtual;
  public
    constructor Create(const AOwner: TPersistent); virtual;
    destructor Destroy; override;
    procedure AssignNotStyled(const ATextSettings: TSkTextSettings; const AStyledSettings: TStyledSettings);
    function Equals(AObject: TObject): Boolean; override;
    procedure UpdateStyledSettings(const AOldTextSettings, ADefaultTextSettings: TSkTextSettings;
      var AStyledSettings: TStyledSettings); virtual;
    property Owner: TPersistent read FOwner;
    property OnChange;
  published
    property Decorations: TDecorations read FDecorations write SetDecorations;
    property Font: TSkFontComponent read FFont write SetFont;
    property FontColor: TAlphaColor read FFontColor write SetFontColor default DefaultFontColor;
    property HeightMultiplier: Single read FHeightMultiplier write SetHeightMultiplier stored IsHeightMultiplierStored;
    property HorzAlign: TSkTextHorzAlign read FHorzAlign write SetHorzAlign default DefaultHorzAlign;
    property LetterSpacing: Single read FLetterSpacing write SetLetterSpacing stored IsLetterSpacingStored;
    property MaxLines: NativeUInt read FMaxLines write SetMaxLines default DefaultMaxLines;
    property Trimming: TTextTrimming read FTrimming write SetTrimming default DefaultTrimming;
    property VertAlign: TTextAlign read FVertAlign write SetVertAlign default DefaultVertAlign;
  end;

  TSkTextSettingsClass = class of TSkTextSettings;

  { ISkTextSettings }

  ISkTextSettings = interface
    ['{CE7E837B-F927-4C78-B1D2-C62EF4A93014}']
    function GetDefaultTextSettings: TSkTextSettings;
    function GetResultingTextSettings: TSkTextSettings;
    function GetStyledSettings: TStyledSettings;
    function GetTextSettings: TSkTextSettings;
    procedure SetStyledSettings(const AValue: TStyledSettings);
    procedure SetTextSettings(const AValue: TSkTextSettings);
    property DefaultTextSettings: TSkTextSettings read GetDefaultTextSettings;
    property ResultingTextSettings: TSkTextSettings read GetResultingTextSettings;
    property StyledSettings: TStyledSettings read GetStyledSettings write SetStyledSettings;
    property TextSettings: TSkTextSettings read GetTextSettings write SetTextSettings;
  end;

  { TSkTextSettingsInfo }

  TSkTextSettingsInfo = class(TPersistent)
  public type
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
    FStyledSettings: TStyledSettings;
    FTextSettings: TSkTextSettings;
    procedure OnCalculatedTextSettings(ASender: TObject);
    procedure OnDefaultChanged(ASender: TObject);
    procedure OnTextChanged(ASender: TObject);
    procedure SetDefaultTextSettings(const AValue: TSkTextSettings);
    procedure SetStyledSettings(const AValue: TStyledSettings);
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
    property StyledSettings: TStyledSettings read FStyledSettings write SetStyledSettings;
    property TextSettings: TSkTextSettings read FTextSettings write SetTextSettings;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  { ISkStyleTextObject }

  ISkStyleTextObject = interface(IFreeNotificationBehavior)
    ['{B5584DD4-D568-4A84-BCD5-C8CB7C068E4D}']
    function GetTextSettings: TSkTextSettings;
    procedure SetTextSettings(const AValue: TSkTextSettings);
    property TextSettings: TSkTextSettings read GetTextSettings write SetTextSettings;
  end;

  { TSkCustomStyleTextObject }

  TSkCustomStyleTextObject = class(TFmxObject, ISkStyleTextObject, IObjectState)
  strict private
    FOnChange: TNotifyEvent;
    FTextSettings: TSkTextSettings;
    FSavedTextSettings: TSkTextSettings;
    function GetTextSettings: TSkTextSettings;
    function RestoreState: Boolean;
    function SaveState: Boolean;
    procedure SetTextSettings(const AValue: TSkTextSettings);
    procedure TextSettingsChange(ASender: TObject);
  strict protected
    function CreateTextSettings: TSkTextSettings; virtual;
    procedure SetName(const ANewName: TComponentName); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property TextSettings: TSkTextSettings read FTextSettings write SetTextSettings;
  end;

  { TSkStyleTextObject }

  [ComponentPlatforms(SkSupportedPlatformsMask)]
  TSkStyleTextObject = class(TSkCustomStyleTextObject)
  published
    property TextSettings;
  end;

  { TSkLabel }

  [ComponentPlatforms(SkSupportedPlatformsMask)]
  TSkLabel = class(TSkStyledControl, ISkTextSettings{$IF CompilerVersion >= 29}, ICaption{$ENDIF})
  public type
    TWordsCollection = class;
    TCustomWordsItemClass = class of TCustomWordsItem;

    TCustomWordsItem = class(TCollectionItem)
    strict protected
      const
        DefaultBackgroundColor = TAlphaColors.Null;
        DefaultCursor = crDefault;
        DefaultFontColor = TAlphaColors.Black;
        DefaultHeightMultiplier = 0;
        DefaultLetterSpacing = 0;
        DefaultName = 'Item 0';
        DefaultText = '';
    strict private
      FBackgroundColor: TAlphaColor;
      FChanged: Boolean;
      FCursor: TCursor;
      FIgnoringAllChanges: Boolean;
      FName: string;
      FOnClick: TNotifyEvent;
      FTag: NativeInt;
      FTagFloat: Single;
      [Weak] FTagObject: TObject;
      FTagString: string;
      FText: string;
      FTextSettingsInfo: TSkTextSettingsInfo;
      FUpdatingCount: Integer;
      [unsafe] FWords: TWordsCollection;
      procedure CheckName(const AName: string; AWordsCollection: TWordsCollection);
      function GetDecorations: TSkTextSettings.TDecorations;
      function GetFont: TSkFontComponent;
      function GetFontColor: TAlphaColor;
      function GetHeightMultiplier: Single;
      function GetLetterSpacing: Single;
      function GetStyledSettings: TStyledSettings;
      function IsFontColorStored: Boolean;
      function IsHeightMultiplierStored: Boolean;
      function IsLetterSpacingStored: Boolean;
      function IsNameStored: Boolean;
      function IsStyledSettingsStored: Boolean;
      function IsTextStored: Boolean;
      procedure TextSettingsChange(ASender: TObject);
      procedure SetBackgroundColor(const AValue: TAlphaColor);
      procedure SetCursor(const AValue: TCursor);
      procedure SetDecorations(const AValue: TSkTextSettings.TDecorations);
      procedure SetFont(const AValue: TSkFontComponent);
      procedure SetFontColor(const AValue: TAlphaColor);
      procedure SetHeightMultiplier(const AValue: Single);
      procedure SetLetterSpacing(const AValue: Single);
      procedure SetName(const AValue: string);
      procedure SetStyledSettings(const AValue: TStyledSettings);
      procedure SetText(const AValue: string);
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
      property Cursor: TCursor read FCursor write SetCursor default crDefault;
      property Decorations: TSkTextSettings.TDecorations read GetDecorations write SetDecorations;
      property Font: TSkFontComponent read GetFont write SetFont;
      property FontColor: TAlphaColor read GetFontColor write SetFontColor stored IsFontColorStored;
      property HeightMultiplier: Single read GetHeightMultiplier write SetHeightMultiplier stored IsHeightMultiplierStored;
      property LetterSpacing: Single read GetLetterSpacing write SetLetterSpacing stored IsLetterSpacingStored;
      /// <summary> The case-insensitive name of the item in the collection. This field cannot be empty and must be unique for his collection </summary>
      property Name: string read FName write SetName stored IsNameStored;
      property StyledSettings: TStyledSettings read GetStyledSettings write SetStyledSettings stored IsStyledSettingsStored;
      property Tag: NativeInt read FTag write FTag default 0;
      property TagFloat: Single read FTagFloat write FTagFloat;
      property TagObject: TObject read FTagObject write FTagObject;
      property TagString: string read FTagString write FTagString;
      property Text: string read FText write SetText stored IsTextStored;
      property Words: TWordsCollection read FWords;
      property OnClick: TNotifyEvent read FOnClick write FOnClick;
    end;

    { TWordsCollection }

    TWordsCollection = class(TOwnedCollection)
    strict protected
      const
        DefaultColor = TAlphaColors.Black;
        DefaultFontSize = 14;
        DefaultFontSlant = TFontSlant.Regular;
        DefaultFontWeight = TFontWeight.Regular;
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
      function Add(const AText: string; const AColor: TAlphaColor = DefaultColor;
        const AFontSize: Single = DefaultFontSize;
        const AFontWeight: TFontWeight = DefaultFontWeight;
        const AFontSlant: TFontSlant = DefaultFontSlant): TCustomWordsItem; overload;
      function AddOrSet(const AName, AText: string; const AFontColor: TAlphaColor = DefaultColor;
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
      property Cursor;
      property Decorations;
      property Font;
      property FontColor;
      property HeightMultiplier;
      property LetterSpacing;
      property Name;
      property StyledSettings;
      property TagString;
      property Text;
      property OnClick;
    end;

    { TItemClickedMessage }

    TItemClickedMessage = class(TMessage<TCustomWordsItem>);
  strict private
    FAutoSize: Boolean;
    FBackgroundPicture: ISkPicture;
    FClickedPosition: TPointF;
    FHasCustomBackground: Boolean;
    FHasCustomCursor: Boolean;
    FLastFillTextFlags: TFillTextFlags;
    FLastMousePosition: TPointF;
    FObjectState: IObjectState;
    FParagraph: ISkParagraph;
    FParagraphBounds: TRectF;
    FParagraphLayoutWidth: Single;
    FParagraphStroked: ISkParagraph;
    {$IF CompilerVersion < 30}
    FPressedPosition: TPointF;
    {$ENDIF}
    FStyleText: ISkStyleTextObject;
    FTextSettingsInfo: TSkTextSettingsInfo;
    FWordsMouseOver: TCustomWordsItem;
    procedure DeleteParagraph;
    procedure GetFitSize(var AWidth, AHeight: Single);
    function GetLinesCount: Integer;
    function GetParagraph: ISkParagraph;
    function GetParagraphBounds: TRectF;
    function GetText: string;
    function HasFitSizeChanged: Boolean;
    procedure ParagraphLayout(AMaxWidth: Single);
    procedure SetAutoSize(const AValue: Boolean);
    procedure SetText(const AValue: string);
    procedure SetWords(const AValue: TWordsCollection);
    {$IF CompilerVersion >= 29}
    { ICaption }
    function TextStored: Boolean;
    {$ENDIF}
  strict private
    { ISkTextSettings }
    function GetDefaultTextSettings: TSkTextSettings;
    function GetResultingTextSettings: TSkTextSettings;
    function GetStyledSettings: TStyledSettings;
    function GetTextSettings: TSkTextSettings;
    procedure SetStyledSettings(const AValue: TStyledSettings);
    procedure SetTextSettings(const AValue: TSkTextSettings);
    procedure UpdateWordsMouseOver;
  strict protected
    FWords: TWordsCollection;  
    procedure ApplyStyle; override;
    procedure Click; override;
    procedure DoEndUpdate; override;
    procedure DoMouseEnter; override;
    procedure DoMouseLeave; override;
    function DoSetSize(const ASize: TControlSize; const ANewPlatformDefault: Boolean; ANewWidth, ANewHeight: Single;
      var ALastWidth, ALastHeight: Single): Boolean; override;
    procedure DoStyleChanged; override;
    procedure Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single); override;
    function FillTextFlags: TFillTextFlags; override;
    procedure FreeStyle; override;
    function GetDefaultSize: TSizeF; override;
    {$IF CompilerVersion > 36}
    function GetDefaultStyleLookupName: string; override;
    {$ENDIF}
    function GetTextSettingsClass: TSkTextSettingsInfo.TCustomTextSettingsClass; virtual;
    function GetWordsItemAtPosition(const AX, AY: Single): TCustomWordsItem;
    function IsStyledSettingsStored: Boolean; virtual;
    procedure Loaded; override;
    procedure MouseClick(AButton: TMouseButton; AShift: TShiftState; AX, AY: Single); override;
    {$IF CompilerVersion < 30}
    procedure MouseDown(AButton: TMouseButton; AShift: TShiftState; AX, AY: Single); override;
    {$ENDIF}
    procedure MouseMove(AShift: TShiftState; AX, AY: Single); override;
    function NormalizeParagraphText(const AText: string): string; virtual;
    function NeedsRedraw: Boolean; override;
    procedure SetAlign(const AValue: TAlignLayout); override;
    procedure SetName(const AValue: TComponentName); override;
    procedure TextSettingsChanged(AValue: TObject); virtual;
    procedure WordsChange(ASender: TObject); virtual;
    property Paragraph: ISkParagraph read GetParagraph;
    property ParagraphBounds: TRectF read GetParagraphBounds;
    property StyleText: ISkStyleTextObject read FStyleText;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function DidExceedMaxLines: Boolean;
    property DefaultTextSettings: TSkTextSettings read GetDefaultTextSettings;
    property LinesCount: Integer read GetLinesCount;
    {$IF CompilerVersion < 30}
    property PressedPosition: TPointF read FPressedPosition write FPressedPosition;
    {$ENDIF}
    property ResultingTextSettings: TSkTextSettings read GetResultingTextSettings;
  published
    property Align;
    property Anchors;
    property ClipChildren default False;
    property ClipParent default False;
    property DragMode default TDragMode.dmManual;
    property Enabled default True;
    property EnableDragHighlight default True;
    property Height;
    property Hint;
    property HitTest default False;
    property Locked default False;
    property Margins;
    property Opacity;
    property Padding;
    {$IF CompilerVersion >= 30}
    property ParentShowHint;
    {$ENDIF}
    property PopupMenu;
    property Position;
    property RotationAngle;
    property RotationCenter;
    property Scale;
    property ShowHint;
    property Size;
    property Visible default True;
    property Width;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragEnd;
    property OnDragEnter;
    property OnDragLeave;
    property OnDragOver;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnPainting;
    property OnResize;
    {$IF CompilerVersion >= 32}
    property OnResized;
    {$ENDIF}
  published
    property AutoSize: Boolean read FAutoSize write SetAutoSize default True;
    property AutoTranslate default True;
    property StyledSettings: TStyledSettings read GetStyledSettings write SetStyledSettings stored IsStyledSettingsStored;
    property StyleLookup;
    property Text: string read GetText write SetText stored False;
    property TextSettings: TSkTextSettings read GetTextSettings write SetTextSettings;
    property TouchTargetExpansion;
    property Words: TWordsCollection read FWords write SetWords;
    property OnApplyStyleLookup;
    property OnDraw;
  end;

  { TSkDefaultProviders }

  TSkDefaultProviders = class sealed
  strict private class var
    FResource: ISkResourceProvider;
    FTypefaceFont: ISkTypefaceFontProvider;
    class constructor Create;
    class destructor Destroy;
  public
    class procedure RegisterTypeface(const AFileName: string); overload; static;
    class procedure RegisterTypeface(const AStream: TStream); overload; static;
    class property Resource: ISkResourceProvider read FResource write FResource;
    class property TypefaceFont: ISkTypefaceFontProvider read FTypefaceFont;
  end;

  { TSkTypefaceManager }

  TSkTypefaceManager = class sealed
  public
    class function Provider: ISkTypefaceFontProvider; static; deprecated 'Use TSkDefaultProviders.TypefaceFont instead';
    class procedure RegisterTypeface(const AFileName: string); overload; static; deprecated 'Use TSkDefaultProviders.RegisterTypeface instead';
    class procedure RegisterTypeface(const AStream: TStream); overload; static; deprecated 'Use TSkDefaultProviders.RegisterTypeface instead';
  end;

procedure AddSkPathToPathData(const APathData: TPathData; const ASkPath: ISkPath);
function BitmapToSkImage(const ABitmap: TBitmap): ISkImage;
procedure DrawDesignBorder(const ACanvas: ISkCanvas; ADest: TRectF; const AOpacity: Single);
function PathDataToSkPath(const APathData: TPathData): ISkPath;
procedure SkiaDraw(const ABitmap: TBitmap; const AProc: TSkDrawProc; const AStartClean: Boolean = True);
function SkImageToBitmap(const AImage: ISkImage): TBitmap;
function SkPathToPathData(const ASkPath: ISkPath): TPathData;

const
  SkFmxColorType: array[TPixelFormat] of TSkColorType = (
    { None     } TSkColorType.Unknown,
    { RGB      } TSkColorType.Unknown,
    { RGBA     } TSkColorType.RGBA8888,
    { BGR      } TSkColorType.Unknown,
    { BGRA     } TSkColorType.BGRA8888,
    { RGBA16   } TSkColorType.RGBA16161616,
    { BGR_565  } TSkColorType.RGB565,
    { BGRA4    } TSkColorType.ARGB4444,
    { BGR4     } TSkColorType.Unknown,
    { BGR5_A1  } TSkColorType.Unknown,
    { BGR5     } TSkColorType.Unknown,
    { BGR10_A2 } TSkColorType.BGRA1010102,
    { RGB10_A2 } TSkColorType.RGBA1010102,
    { L        } TSkColorType.Gray8,
    { LA       } TSkColorType.Unknown,
    { LA4      } TSkColorType.Unknown,
    { L16      } TSkColorType.Unknown,
    { A        } TSkColorType.Alpha8,
    { R16F     } TSkColorType.AlphaF16,
    { RG16F    } TSkColorType.RGF16,
    { RGBA16F  } TSkColorType.RGBAF16,
    { R32F     } TSkColorType.Unknown,
    { RG32F    } TSkColorType.Unknown,
    { RGBA32F  } TSkColorType.RGBAF32
  );

  SkFmxPixelFormat: array[TSkColorType] of TPixelFormat = (
    { Unknown           } TPixelFormat.None,
    { Alpha8            } TPixelFormat.A,
    { RGB565            } TPixelFormat.BGR_565,
    { ARGB4444          } TPixelFormat.BGRA4,
    { RGBA8888          } TPixelFormat.RGBA,
    { RGB888X           } TPixelFormat.None,
    { BGRA8888          } TPixelFormat.BGRA,
    { RGBA1010102       } TPixelFormat.RGB10_A2,
    { BGRA1010102       } TPixelFormat.BGR10_A2,
    { RGB101010X        } TPixelFormat.None,
    { BGR101010X        } TPixelFormat.None,
    { Gray8             } TPixelFormat.L,
    { RGBAF16Normalized } TPixelFormat.RGBA16F,
    { RGBAF16           } TPixelFormat.RGBA16F,
    { RGBAF32           } TPixelFormat.RGBA32F,
    { RG88              } TPixelFormat.None,
    { AlphaF16          } TPixelFormat.R16F,
    { RGF16             } TPixelFormat.RG16F,
    { Alpha16           } TPixelFormat.None,
    { RG1616            } TPixelFormat.None,
    { RGBA16161616      } TPixelFormat.RGBA16,
    { SRGBA8888         } TPixelFormat.None,
    { R8                } TPixelFormat.None
  );

var
  /// <summary> Allows use of Skia Canvas for UI rendering, replacing FMX's default Canvas </summary>
  GlobalUseSkia: Boolean;
  /// <summary> Allows the UI rendering in Skia Canvas to use the CPU instead of the GPU (only takes effect on Windows currently) </summary>
  GlobalUseSkiaRasterWhenAvailable: Boolean = True;
  /// <summary> Disables registration of Skia image codecs </summary>
  GlobalDisableSkiaCodecsReplacement: Boolean;
  {$IF CompilerVersion >= 36}
  /// <summary> Enables the execution of FMX filters/effects by Skia </summary>
  /// <remarks> This option is only valid when the Canvas is Skia based and uses a GPU </remarks>
  GlobalUseSkiaFilters: Boolean = True;
  /// <summary> Enables TBitmaps to be drawn in true parallel to UI and other bitmaps, when drawing in a thread (only takes effect when GlobalUseSkia is True) [Experimental] </summary>
  GlobalSkiaBitmapsInParallel: Boolean;
  {$ENDIF}
  /// <summary> Specifies the locale to determine language-specific rules for texts rendered by Skia. </summary>
  GlobalSkiaTextLocale: string;

implementation

uses
  { Delphi }
  System.Math.Vectors,
  System.ZLib,
  System.IOUtils,
  System.TypInfo,
  System.Character,
  System.Generics.Defaults,
  System.RTLConsts,
  {$IF CompilerVersion >= 29}
  FMX.Utils,
  {$ENDIF}
  FMX.Platform,
  FMX.BehaviorManager,
  {$IF CompilerVersion >= 36}
  FMX.FontManager,
  FMX.Consts,
  {$ENDIF}
  FMX.Forms,
  FMX.Ani,

  { Skia }
  FMX.Skia.Canvas;

type
  { TSkDefaultAnimationCodec }

  TSkDefaultAnimationCodec = class(TSkAnimatedImage.TAnimationCodec)
  strict private type
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
  strict private type
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

  {$IF CompilerVersion >= 36}
  { TSkFontManagerService }

  TSkFontManagerService = class(TSkTypefaceFontProvider, IFMXFontManagerService)
  strict private
    FFontFamilyNames: TDictionary<TFontName, TFontName>;
    FFontInfos: TList<TFontInfo>;
    FOriginalService: IFMXFontManagerService;
    procedure AddFamilyName(const AFamilyName: string);
  strict protected
    procedure RegisterTypeface(const ATypeface: ISkTypeface); overload; override;
    procedure RegisterTypeface(const ATypeface: ISkTypeface; const AFamilyName: string); overload; override;
  public
    constructor Create;
    destructor Destroy; override;
    { IFMXFontManagerService }
    function AddCustomFontFromFile(const AFileName: TFileName): Boolean;
    function AddCustomFontFromResource(const AResourceName: string): Boolean;
    function AddCustomFontFromStream(const AStream: TStream): Boolean;
    function HasCustomFont(const AFontFamily: TFontName): Boolean;
    function HasCustomFonts: Boolean;
    function GetCustomFontInfo(const AIndex: Integer): TFontInfo;
    function GetCustomFontInfoCount: Integer;
  end;
  {$ENDIF}

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

const
  SkFontSlant : array[TFontSlant] of TSkFontSlant = (TSkFontSlant.Upright, TSkFontSlant.Italic,
    // SkParagraph does not support oblique fonts on macOS on m107
    {$IFDEF MACOS}TSkFontSlant.Italic{$ELSE}TSkFontSlant.Oblique{$ENDIF});
  SkFontWeightValue: array[TFontWeight] of Integer = (100, 200, 300, 350, 400, 500, 600, 700, 800, 900, 950);
  SkFontWidthValue: array[TFontStretch] of Integer = (1, 2, 3, 4, 5, 6, 7, 8, 9);

resourcestring
  ControlExceededBitmapLimitWarning = 'A control has exceeded the size allowed for a bitmap (class %s, name "%s"). We will reduce the drawing quality to avoid this exception. Consider using "GlobalUseSkia := True" to avoid this kind of problem.';

procedure AddSkPathToPathData(const APathData: TPathData; const ASkPath: ISkPath);
begin
  APathData.AddSkPath(ASkPath);
end;

function BitmapToSkImage(const ABitmap: TBitmap): ISkImage;
begin
  Result := ABitmap.ToSkImage;
end;

function CeilFloat(const X: Single): Single;
begin
  Result := Int(X);
  if Frac(X) > 0 then
    Result := Result + 1;
end;

procedure DrawDesignBorder(const ACanvas: ISkCanvas; ADest: TRectF; const AOpacity: Single);
const
  DesignBorderColor = $A0909090;
var
  LPaint: ISkPaint;
begin
  LPaint := TSkPaint.Create(TSkPaintStyle.Stroke);
  LPaint.Color := DesignBorderColor;
  LPaint.AlphaF := AOpacity;
  LPaint.StrokeWidth := 1;
  LPaint.PathEffect := TSkPathEffect.MakeDash([3, 1], 0);

  InflateRect(ADest, -0.5, -0.5);
  ACanvas.DrawRect(ADest, LPaint);
end;

function IsSameBytes(const ALeft, ARight: TBytes): Boolean;
begin
  Result := (ALeft = ARight) or
    ((Length(ALeft) = Length(ARight)) and
    ((Length(ALeft) = 0) or CompareMem(PByte(@ALeft[0]), PByte(@ARight[0]), Length(ALeft))));
end;

function PathDataToSkPath(const APathData: TPathData): ISkPath;
begin
  Result := APathData.ToSkPath;
end;

function PlaceIntoTopLeft(const ASourceRect, ADesignatedArea: TRectF): TRectF;
begin
  Result := ASourceRect;
  if (ASourceRect.Width > ADesignatedArea.Width) or (ASourceRect.Height > ADesignatedArea.Height) then
    Result := Result.FitInto(ADesignatedArea);
  Result.SetLocation(ADesignatedArea.TopLeft);
end;

procedure SkiaDraw(const ABitmap: TBitmap; const AProc: TSkDrawProc; const AStartClean: Boolean);
begin
  ABitmap.SkiaDraw(AProc, AStartClean);
end;

function SkImageToBitmap(const AImage: ISkImage): TBitmap;
begin
  Result := TBitmap.CreateFromSkImage(AImage);
end;

function SkPathToPathData(const ASkPath: ISkPath): TPathData;
begin
  Result := TPathData.CreateFromSkPath(ASkPath);
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

constructor TSkBitmapHelper.CreateFromSkImage(const AImage: ISkImage);
var
  LData: TBitmapData;
begin
  Assert(Assigned(AImage));
  Create(AImage.Width, AImage.Height);
  if (not IsEmpty) and Map(TMapAccess.Write, LData) then
  begin
    try
      AImage.ReadPixels(TSkImageInfo.Create(Width, Height, SkFmxColorType[LData.PixelFormat]), LData.Data, LData.Pitch);
    finally
      Unmap(LData);
    end;
  end;
end;

procedure TSkBitmapHelper.SkiaDraw(const AProc: TSkDrawProc; const AStartClean: Boolean);

  procedure Draw(const ACanvas: ISkCanvas);
  begin
    if AStartClean then
      ACanvas.Clear(TAlphaColors.Null);
    AProc(ACanvas);
  end;

var
  LAccess: TMapAccess;
  {$IF (CompilerVersion < 35) or ((CompilerVersion = 35) and not DECLARED(RTLVersion113))}
  LBeginSceneCount: Integer;
  {$ENDIF}
  LColorType: TSkColorType;
  LData: TBitmapData;
  LSurface: ISkSurface;
begin
  Assert(Assigned(AProc));
  if IsEmpty then
    raise ESkBitmapHelper.Create('Invalid bitmap');
  if CanvasClass.InheritsFrom(TSkCanvasCustom) then
  begin
    {$REGION ' - Workaround RSP-38418'}
    // - -----------------------------------------------------------------------
    // - WORKAROUND
    // - -----------------------------------------------------------------------
    // -
    // - Description:
    // -   This code is a workaround intended to fix issue when changes the
    // -   bitmap that has been assign to another.
    // -
    // - Bug report:
    // -   https://quality.embarcadero.com/browse/RSP-38418
    // -
    // - -----------------------------------------------------------------------
    {$IF (CompilerVersion < 35) or ((CompilerVersion = 35) and not DECLARED(RTLVersion113))}
    if Image.RefCount > 1 then
    begin
      LBeginSceneCount := Canvas.BeginSceneCount;
      CopyToNewReference;
      while LBeginSceneCount > 0 do
      begin
        Canvas.BeginScene;
        Dec(LBeginSceneCount);
      end;
    end;
    {$ENDIF}
    // - -----------------------------------------------------------------------
    {$ENDREGION}
    if Canvas.BeginSceneCount = 0 then
    begin
      if Canvas.BeginScene then
      begin
        try
          Draw(TSkCanvasCustom(Canvas).Canvas);
        finally
          Canvas.EndScene;
        end;
      end;
    end
    else
      Draw(TSkCanvasCustom(Canvas).Canvas);
  end
  else
  begin
    case PixelFormat of
      TPixelFormat.RGBA: LColorType := TSkColorType.RGBA8888;
      TPixelFormat.BGRA: LColorType := TSkColorType.BGRA8888;
    else
      raise ESkBitmapHelper.Create('Invalid pixelformat');
    end;
    if AStartClean then
      LAccess := TMapAccess.Write
    else
      LAccess := TMapAccess.ReadWrite;
    if Map(LAccess, LData) then
      try
        LSurface := TSkSurface.MakeRasterDirect(TSkImageInfo.Create(LData.Width, LData.Height, LColorType), LData.Data, LData.Pitch);
        LSurface.Canvas.Scale(BitmapScale, BitmapScale);
        Draw(LSurface.Canvas);
      finally
        Unmap(LData);
      end;
  end;
end;

function TSkBitmapHelper.ToSkImage: ISkImage;
var
  LColorType: TSkColorType;
  LData: TBitmapData;
begin
  if IsEmpty then
    raise ESkBitmapHelper.Create('Invalid bitmap');
  case PixelFormat of
    TPixelFormat.RGBA: LColorType := TSkColorType.RGBA8888;
    TPixelFormat.BGRA: LColorType := TSkColorType.BGRA8888;
  else
    raise ESkBitmapHelper.Create('Invalid pixelformat');
  end;
  if not Map(TMapAccess.Read, LData) then
    raise ESkBitmapHelper.Create('Could not map the bitmap');
  try
    Result := TSkImage.MakeRasterCopy(TSkImageInfo.Create(Width, Height, LColorType), LData.Data, LData.Pitch);
  finally
    Unmap(LData);
  end;
end;

{ TSkPathDataHelper }

procedure TSkPathDataHelper.AddSkPath(const AValue: ISkPath);
var
  LElem: TSkPathIteratorElem;
  LPoints: TArray<TPointF>;
begin
  for LElem in AValue.GetIterator(False) do
  begin
    case LElem.Verb of
      TSkPathVerb.Move  : MoveTo(LElem.Points[0]);
      TSkPathVerb.Line  : LineTo(LElem.Points[1]);
      TSkPathVerb.Quad  : QuadCurveTo(LElem.Points[1], LElem.Points[2]);
      TSkPathVerb.Conic :
        begin
          LPoints := TSkPath.ConvertConicToQuads(LElem.Points[0], LElem.Points[1], LElem.Points[2], LElem.ConicWeight, 1);
          QuadCurveTo(LPoints[1], LPoints[2]);
          QuadCurveTo(LPoints[3], LPoints[4]);
        end;
      TSkPathVerb.Cubic : CurveTo(LElem.Points[1], LElem.Points[2], LElem.Points[3]);
      TSkPathVerb.Close : ClosePath;
    end;
  end;
end;

constructor TSkPathDataHelper.CreateFromSkPath(const AValue: ISkPath);
begin
  Create;
  AddSkPath(AValue);
end;

procedure TSkPathDataHelper.FromSkPath(const AValue: ISkPath);
begin
  Clear;
  AddSkPath(AValue);
end;

function TSkPathDataHelper.ToSkPath: ISkPath;
var
  I: Integer;
  LPathBuilder: ISkPathBuilder;
begin
  LPathBuilder := TSkPathBuilder.Create(TSkPathFillType.EvenOdd);
  I := 0;
  while I < Count do
  begin
    case Points[I].Kind of
      TPathPointKind.MoveTo  : LPathBuilder.MoveTo(Points[I].Point);
      TPathPointKind.LineTo  : LPathBuilder.LineTo(Points[I].Point);
      TPathPointKind.Close   : LPathBuilder.Close;
      TPathPointKind.CurveTo :
        begin
          LPathBuilder.CubicTo(Points[I].Point, Points[I + 1].Point, Points[I + 2].Point);
          Inc(I, 2);
        end;
    end;
    Inc(I);
  end;
  Result := LPathBuilder.Detach;
end;

{ TSkPersistent }

procedure TSkPersistent.AfterConstruction;
begin
  inherited;
  FCreated := True;
end;

procedure TSkPersistent.Assign(ASource: TPersistent);
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

procedure TSkPersistent.BeginUpdate;
begin
  BeginUpdate(False);
end;

procedure TSkPersistent.BeginUpdate(const AIgnoreAllChanges: Boolean);
begin
  Inc(FUpdatingCount);
  FIgnoringAllChanges := FIgnoringAllChanges or AIgnoreAllChanges;
end;

procedure TSkPersistent.Change;
begin
  if FUpdatingCount > 0 then
    FChanged := True
  else
  begin
    FChanged := False;
    DoChanged;
  end;
end;

procedure TSkPersistent.DoAssign(ASource: TPersistent);
begin
  inherited Assign(ASource);
end;

procedure TSkPersistent.DoChanged;
begin
  if FCreated and Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TSkPersistent.EndUpdate;
begin
  EndUpdate(False);
end;

procedure TSkPersistent.EndUpdate(const AIgnoreAllChanges: Boolean);
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

function TSkPersistent.GetHasChanged: Boolean;
begin
  Result := FChanged;
end;

function TSkPersistent.GetUpdating: Boolean;
begin
  Result := FUpdatingCount > 0;
end;

function TSkPersistent.SetValue(var AField: Byte; const AValue: Byte): Boolean;
begin
  Result := AField <> AValue;
  if Result then
  begin
    AField := AValue;
    Change;
  end;
end;

function TSkPersistent.SetValue(var AField: Word; const AValue: Word): Boolean;
begin
  Result := AField <> AValue;
  if Result then
  begin
    AField := AValue;
    Change;
  end;
end;

function TSkPersistent.SetValue(var AField: Double; const AValue,
  AEpsilon: Double): Boolean;
begin
  Result := not SameValue(AField, AValue, AEpsilon);
  if Result then
  begin
    AField := AValue;
    Change;
  end;
end;

function TSkPersistent.SetValue(var AField: TBytes; const AValue: TBytes): Boolean;
begin
  Result := not IsSameBytes(AField, AValue);
  if Result then
  begin
    AField := Copy(AValue);
    Change;
  end;
end;

function TSkPersistent.SetValue(var AField: string; const AValue: string): Boolean;
begin
  Result := AField <> AValue;
  if Result then
  begin
    AField := AValue;
    Change;
  end;
end;

function TSkPersistent.SetValue(var AField: Single; const AValue,
  AEpsilon: Single): Boolean;
begin
  Result := not SameValue(AField, AValue, AEpsilon);
  if Result then
  begin
    AField := AValue;
    Change;
  end;
end;

function TSkPersistent.SetValue(var AField: Boolean;
  const AValue: Boolean): Boolean;
begin
  Result := AField <> AValue;
  if Result then
  begin
    AField := AValue;
    Change;
  end;
end;

function TSkPersistent.SetValue(var AField: Cardinal;
  const AValue: Cardinal): Boolean;
begin
  Result := AField <> AValue;
  if Result then
  begin
    AField := AValue;
    Change;
  end;
end;

function TSkPersistent.SetValue(var AField: Integer;
  const AValue: Integer): Boolean;
begin
  Result := AField <> AValue;
  if Result then
  begin
    AField := AValue;
    Change;
  end;
end;

function TSkPersistent.SetValue(var AField: Int64; const AValue: Int64): Boolean;
begin
  Result := AField <> AValue;
  if Result then
  begin
    AField := AValue;
    Change;
  end;
end;

function TSkPersistent.SetValue<T>(var AField: T; const AValue: T): Boolean;
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

{ TSkCustomControl }

constructor TSkCustomControl.Create(AOwner: TComponent);
begin
  inherited;
  FDrawCacheKind := TSkDrawCacheKind.Raster;
  HitTest := False;
end;

destructor TSkCustomControl.Destroy;
begin
  FBuffer.Free;
  inherited;
end;

procedure TSkCustomControl.Draw(const ACanvas: ISkCanvas; const ADest: TRectF;
  const AOpacity: Single);
begin
  if (csDesigning in ComponentState) and not Locked then
    FMX.Skia.DrawDesignBorder(ACanvas, ADest, AOpacity);
end;

function TSkCustomControl.NeedsRedraw: Boolean;
begin
  Result := (not FDrawCached) or (FDrawCacheKind = TSkDrawCacheKind.Never) or (FBuffer = nil);
end;

procedure TSkCustomControl.Paint;
var
  LAbsoluteBimapSize: TSize;
  LAbsoluteScale: TPointF;
  LAbsoluteSize: TSize;
  LExceededRatio: Single;
  LMaxBitmapSize: Integer;
  LSceneScale: Single;
begin
  if ((FDrawCacheKind = TSkDrawCacheKind.Never) and (Canvas is TSkCanvasCustom)) or
    ((FDrawCacheKind = TSkDrawCacheKind.Raster) and (Canvas is TGrCanvas)) then
  begin
    Draw(TSkCanvasCustom(Canvas).Canvas, LocalRect, AbsoluteOpacity);
    if Assigned(FOnDraw) then
      FOnDraw(Self, TSkCanvasCustom(Canvas).Canvas, LocalRect, AbsoluteOpacity);
    FreeAndNil(FBuffer);
  end
  else
  begin
    if Assigned(Scene) then
      LSceneScale := Scene.GetSceneScale
    else
      LSceneScale := 1;
    LAbsoluteScale := AbsoluteScale;
    LAbsoluteSize := TSize.Create(Round(Width * LAbsoluteScale.X * LSceneScale), Round(Height * LAbsoluteScale.Y * LSceneScale));

    LMaxBitmapSize := Canvas.GetAttribute(TCanvasAttribute.MaxBitmapSize);
    if (LAbsoluteSize.Width > LMaxBitmapSize) or (LAbsoluteSize.Height > LMaxBitmapSize) then
    begin
      LAbsoluteBimapSize := RectF(0, 0, LAbsoluteSize.Width, LAbsoluteSize.Height)
        .FitInto(RectF(0, 0, LMaxBitmapSize, LMaxBitmapSize), LExceededRatio).Size.Round;
      if NeedsRedraw or (TSize.Create(FBuffer.Width, FBuffer.Height) <> LAbsoluteBimapSize) then
        Log.d(Format(ControlExceededBitmapLimitWarning, [ClassName, Name]));
    end
    else
    begin
      LAbsoluteBimapSize := LAbsoluteSize;
      LExceededRatio := 1;
    end;

    if NeedsRedraw or (TSize.Create(FBuffer.Width, FBuffer.Height) <> LAbsoluteBimapSize) then
    begin
      if FBuffer = nil then
        FBuffer := TBitmap.Create(LAbsoluteBimapSize.Width, LAbsoluteBimapSize.Height)
      else if TSize.Create(FBuffer.Width, FBuffer.Height) <> LAbsoluteBimapSize then
        FBuffer.SetSize(LAbsoluteBimapSize.Width, LAbsoluteBimapSize.Height);
      FBuffer.SkiaDraw(
        procedure(const ACanvas: ISkCanvas)
        var
          LAbsoluteScale: TPointF;
        begin
          ACanvas.Clear(TAlphaColors.Null);
          LAbsoluteScale := AbsoluteScale * LSceneScale / LExceededRatio;
          ACanvas.Concat(TMatrix.CreateScaling(LAbsoluteScale.X, LAbsoluteScale.Y));
          Draw(ACanvas, LocalRect, 1);
          if Assigned(FOnDraw) then
            FOnDraw(Self, ACanvas, LocalRect, 1);
        end, False);
      FDrawCached := True;
    end;
    Canvas.DrawBitmap(FBuffer, RectF(0, 0, FBuffer.Width, FBuffer.Height),
      RectF(0, 0, FBuffer.Width / (LAbsoluteScale.X * LSceneScale / LExceededRatio),
      FBuffer.Height / (LAbsoluteScale.Y * LSceneScale / LExceededRatio)), AbsoluteOpacity);
  end;
end;

procedure TSkCustomControl.Redraw;
begin
  FDrawCached := False;
  Repaint;
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

{ TSkStyledControl }

constructor TSkStyledControl.Create(AOwner: TComponent);
begin
  inherited;
  FDrawCacheKind := TSkDrawCacheKind.Raster;
  HitTest := False;
end;

destructor TSkStyledControl.Destroy;
begin
  FBuffer.Free;
  inherited;
end;

procedure TSkStyledControl.Draw(const ACanvas: ISkCanvas; const ADest: TRectF;
  const AOpacity: Single);
begin
  if (csDesigning in ComponentState) and not Locked then
    FMX.Skia.DrawDesignBorder(ACanvas, ADest, AOpacity);
end;

function TSkStyledControl.NeedsRedraw: Boolean;
begin
  Result := (not FDrawCached) or (FDrawCacheKind = TSkDrawCacheKind.Never) or (FBuffer = nil);
end;

procedure TSkStyledControl.Paint;
var
  LAbsoluteBimapSize: TSize;
  LAbsoluteScale: TPointF;
  LAbsoluteSize: TSize;
  LExceededRatio: Single;
  LMaxBitmapSize: Integer;
  LSceneScale: Single;
begin
  if ((FDrawCacheKind = TSkDrawCacheKind.Never) and (Canvas is TSkCanvasCustom)) or
    ((FDrawCacheKind = TSkDrawCacheKind.Raster) and (Canvas is TGrCanvas)) then
  begin
    Draw(TSkCanvasCustom(Canvas).Canvas, LocalRect, AbsoluteOpacity);
    if Assigned(FOnDraw) then
      FOnDraw(Self, TSkCanvasCustom(Canvas).Canvas, LocalRect, AbsoluteOpacity);
    FreeAndNil(FBuffer);
  end
  else
  begin
    if Assigned(Scene) then
      LSceneScale := Scene.GetSceneScale
    else
      LSceneScale := 1;
    LAbsoluteScale := AbsoluteScale;
    LAbsoluteSize := TSize.Create(Round(Width * LAbsoluteScale.X * LSceneScale),
      Round(Height * LAbsoluteScale.Y * LSceneScale));

    LMaxBitmapSize := Canvas.GetAttribute(TCanvasAttribute.MaxBitmapSize);
    if (LAbsoluteSize.Width > LMaxBitmapSize) or (LAbsoluteSize.Height > LMaxBitmapSize) then
    begin
      LAbsoluteBimapSize := RectF(0, 0, LAbsoluteSize.Width, LAbsoluteSize.Height)
        .FitInto(RectF(0, 0, LMaxBitmapSize, LMaxBitmapSize), LExceededRatio).Size.Round;
      if NeedsRedraw or (TSize.Create(FBuffer.Width, FBuffer.Height) <> LAbsoluteBimapSize) then
        Log.d(Format(ControlExceededBitmapLimitWarning, [ClassName, Name]));
    end
    else
    begin
      LAbsoluteBimapSize := LAbsoluteSize;
      LExceededRatio := 1;
    end;

    if NeedsRedraw or (TSize.Create(FBuffer.Width, FBuffer.Height) <> LAbsoluteBimapSize) then
    begin
      if FBuffer = nil then
        FBuffer := TBitmap.Create(LAbsoluteBimapSize.Width, LAbsoluteBimapSize.Height)
      else if TSize.Create(FBuffer.Width, FBuffer.Height) <> LAbsoluteBimapSize then
        FBuffer.SetSize(LAbsoluteBimapSize.Width, LAbsoluteBimapSize.Height);
      FBuffer.SkiaDraw(
        procedure(const ACanvas: ISkCanvas)
        var
          LAbsoluteScale: TPointF;
        begin
          ACanvas.Clear(TAlphaColors.Null);
          LAbsoluteScale := AbsoluteScale * LSceneScale / LExceededRatio;
          ACanvas.Concat(TMatrix.CreateScaling(LAbsoluteScale.X, LAbsoluteScale.Y));
          Draw(ACanvas, LocalRect, 1);
          if Assigned(FOnDraw) then
            FOnDraw(Self, ACanvas, LocalRect, 1);
        end, False);
      FDrawCached := True;
    end;
    Canvas.DrawBitmap(FBuffer, RectF(0, 0, FBuffer.Width, FBuffer.Height),
      RectF(0, 0, FBuffer.Width / (LAbsoluteScale.X * LSceneScale / LExceededRatio),
      FBuffer.Height / (LAbsoluteScale.Y * LSceneScale / LExceededRatio)), AbsoluteOpacity);
  end;
end;

procedure TSkStyledControl.Redraw;
begin
  FDrawCached := False;
  Repaint;
end;

procedure TSkStyledControl.SetDrawCacheKind(const AValue: TSkDrawCacheKind);
begin
  if FDrawCacheKind <> AValue then
  begin
    FDrawCacheKind := AValue;
    if AValue <> TSkDrawCacheKind.Always then
      Repaint;
  end;
end;

procedure TSkStyledControl.SetOnDraw(const AValue: TSkDrawEvent);
begin
  if TMethod(FOnDraw) <> TMethod(AValue) then
  begin
    FOnDraw := AValue;
    Redraw;
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
  Result := TSkSVGDOM.Make(FSource, TSkDefaultProviders.Resource);
end;

procedure TSkSvgBrush.RecreateDOM;
begin
  FDOM := nil;
  FOriginalSize := TSizeF.Create(0, 0);
end;

procedure TSkSvgBrush.Render(const ACanvas: ISkCanvas; const ADestRect: TRectF;
  const AOpacity: Single);

  function GetWrappedDest(const ADOM: ISkSVGDOM; const ASvgRect, ADestRect: TRectF;
    const AIntrinsicSize: TSizeF): TRectF;
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
        LCanvas.Scale(AWrappedDest.Width / ASvgRect.Width, AWrappedDest.Height / ASvgRect.Height);
        ADOM.Root.Width  := TSkSVGLength.Create(ASvgRect.Width,  TSkSVGLengthUnit.Pixel);
        ADOM.Root.Height := TSkSVGLength.Create(ASvgRect.Height, TSkSVGLengthUnit.Pixel);
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
              ACanvas.Scale(LWrappedDest.Width / LSvgRect.Width, LWrappedDest.Height / LSvgRect.Height);
              LDOM.Root.Width  := TSkSVGLength.Create(LSvgRect.Width,  TSkSVGLengthUnit.Pixel);
              LDOM.Root.Height := TSkSVGLength.Create(LSvgRect.Height, TSkSVGLengthUnit.Pixel);
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

{ TBasicAnimation }

type
  TBasicAnimation = class(TAnimation)
  protected
    procedure ProcessAnimation; override;
  end;

procedure TBasicAnimation.ProcessAnimation;
begin
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
  if not TPlatformServices.Current.SupportsPlatformService(IFMXTimerService, FTimerService) then
    raise EUnsupportedPlatformService.Create('IFMXTimerService');
  FAniList := TList<Pointer>.Create;
  FAniProcessingList := TList<Pointer>.Create;
  FAnimation := TBasicAnimation.Create(nil);
  TBasicAnimation(FAnimation).Loop := True;
  TBasicAnimation(FAnimation).Duration := 30;
  TBasicAnimation(FAnimation).OnProcess := OnProcess;
  FMainFormChangedMessageId := TMessageManager.DefaultManager.SubscribeToMessage(TMainFormChangedMessage, MainFormChangeHandler);
end;

destructor TSkCustomAnimation.TProcess.Destroy;
begin
  TMessageManager.DefaultManager.Unsubscribe(TMainFormChangedMessage, FMainFormChangedMessageId);
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
  if not TBasicAnimation(FAnimation).Enabled and (FAniList.Count > 0) then
  begin
    FTime := FTimerService.GetTick;
    if Assigned(Application.MainForm) then
    begin
      FAnimation.SetRoot(Application.MainForm);
      FAniRoot := nil;
    end
    else if Assigned(AAnimation.Root) then
    begin
      FAnimation.SetRoot(AAnimation.Root);
      FAniRoot := AAnimation;
    end;
  end;
  TBasicAnimation(FAnimation).Enabled := Assigned(FAnimation.Root) and (FAniList.Count > 0);
end;

procedure TSkCustomAnimation.TProcess.DoRemove(const AAnimation: TSkCustomAnimation);
begin
  if FAniList <> nil then
  begin
    FAniList.Remove(AAnimation);
    FAniProcessingList.Remove(AAnimation);
    if FAniRoot = AAnimation then
    begin
      FAnimation.SetRoot(nil);
      FAniRoot := nil;
      TryFindRoot;
    end;
    TBasicAnimation(FAnimation).Enabled := Assigned(FAnimation.Root) and (FAniList.Count > 0);
  end;
end;

procedure TSkCustomAnimation.TProcess.DoRootChanged(const AAnimation: TSkCustomAnimation);
begin
  if FAniRoot = AAnimation then
  begin
    FAnimation.SetRoot(nil);
    FAniRoot := nil;
    TryFindRoot;
  end
  else if not Assigned(FAnimation.Root) and Assigned(AAnimation.Root) then
  begin
    FAnimation.SetRoot(AAnimation.Root);
    FAniRoot := AAnimation;
  end;
  TBasicAnimation(FAnimation).Enabled := Assigned(FAnimation.Root) and (FAniList.Count > 0);
end;

procedure TSkCustomAnimation.TProcess.MainFormChangeHandler(
  const ASender: TObject; const AMessage: TMessage);
begin
  FAnimation.SetRoot(nil);
  TryFindRoot;
end;

procedure TSkCustomAnimation.TProcess.OnProcess(ASender: TObject);
var
  I: Integer;
  LNewTime: Double;
  LDeltaTime: Double;
  [unsafe] LAnimation: TSkCustomAnimation;
begin
  LNewTime := FTimerService.GetTick;
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

class procedure TSkCustomAnimation.TProcess.RootChanged(
  const AAnimation: TSkCustomAnimation);
begin
  if FProcess <> nil then
    FProcess.DoRootChanged(AAnimation);
end;

procedure TSkCustomAnimation.TProcess.TryFindRoot;
var
  I: Integer;
begin
  if Assigned(Application.MainForm) then
  begin
    FAnimation.SetRoot(Application.MainForm);
    FAniRoot := nil;
  end
  else
  begin
    for I := 0 to FAniList.Count - 1 do
    begin
      if Assigned(TSkCustomAnimation(FAniList[I]).Root) then
      begin
        FAniRoot := TSkCustomAnimation(FAniList[I]);
        FAnimation.SetRoot(FAniRoot.Root);
        Break;
      end;
    end;
  end;
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

function TSkCustomAnimation.GetRoot: IRoot;
begin
  if FOwner is TFmxObject then
    Result := TFmxObject(FOwner).Root
  else
    Result := nil;
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

procedure TSkCustomAnimation.RootChanged;
begin
  if FProcessing then
    TProcess.RootChanged(Self);
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
      FProgress := FStopProgress
    else
      FProgress := FStartProgress;
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

procedure TSkCustomAnimatedControl.AncestorVisibleChanged(const AVisible: Boolean);
var
  LLastAbsoluteVisible: Boolean;
begin
  LLastAbsoluteVisible := FAbsoluteVisible;
  if not AVisible then
  begin
    FAbsoluteVisible := False;
    FAbsoluteVisibleCached := True;
  end
  else
    FAbsoluteVisibleCached := False;
  if Assigned(FAnimation) and FAnimation.Loop and FAnimation.Running and (not LLastAbsoluteVisible) and AbsoluteVisible then
    FAnimation.Start;
  CheckAnimation;
  inherited;
end;

function TSkCustomAnimatedControl.CanRunAnimation: Boolean;
begin
  Result := Assigned(Scene) and ([csDestroying, csLoading] * ComponentState = []) and
    AbsoluteVisible and
    (not SameValue(AbsoluteWidth, 0, TEpsilon.Position)) and
    (not SameValue(AbsoluteHeight, 0, TEpsilon.Position)) and
    (Scene.GetObject is TCommonCustomForm) and TCommonCustomForm(Scene.GetObject).Visible;
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

constructor TSkCustomAnimatedControl.Create(AOwner: TComponent);
begin
  inherited;
  FAnimation := CreateAnimation;
  FAbsoluteVisible := Visible;
  FAbsoluteVisibleCached := True;
  CheckDuration;
end;

destructor TSkCustomAnimatedControl.Destroy;
begin
  FreeAndNil(FAnimation);
  inherited;
end;

procedure TSkCustomAnimatedControl.DoAnimationChanged;
begin
  CheckDuration;
  if csDesigning in ComponentState then
    Repaint;
end;

procedure TSkCustomAnimatedControl.DoAnimationFinish;
begin
  Redraw;
  if Assigned(FOnAnimationFinish) then
    FOnAnimationFinish(Self);
end;

procedure TSkCustomAnimatedControl.DoAnimationProcess;
begin
  if not FSuccessRedraw then
    CheckAnimation;
  FSuccessRedraw := False;
  Redraw;
  if Assigned(FOnAnimationProcess) then
    FOnAnimationProcess(Self);
end;

procedure TSkCustomAnimatedControl.DoAnimationStart;
begin
  if Assigned(FOnAnimationStart) then
    FOnAnimationStart(Self);
end;

procedure TSkCustomAnimatedControl.DoRootChanged;
begin
  inherited;
  if Assigned(FAnimation) then
    FAnimation.RootChanged;
end;

procedure TSkCustomAnimatedControl.Draw(const ACanvas: ISkCanvas;
  const ADest: TRectF; const AOpacity: Single);
begin
  inherited;
  if not FAnimation.AllowAnimation then
    CheckAnimation;
  FAnimation.BeforePaint;
  RenderFrame(ACanvas, ADest, FAnimation.Progress, AOpacity);
  FSuccessRedraw := True;
end;

function TSkCustomAnimatedControl.GetAbsoluteVisible: Boolean;
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

procedure TSkCustomAnimatedControl.SetNewScene(AScene: IScene);
var
  LCanCheck: Boolean;
begin
  LCanCheck := Scene = nil;
  inherited;
  if LCanCheck then
    CheckAnimation;
end;

procedure TSkCustomAnimatedControl.SetOnAnimationDraw(
  const AValue: TSkAnimationDrawEvent);
begin
  if TMethod(FOnAnimationDraw) <> TMethod(AValue) then
  begin
    FOnAnimationDraw := AValue;
    Redraw;
  end;
end;

{ TSkAnimatedPaintBox.TAnimation }

constructor TSkAnimatedPaintBox.TAnimation.Create(const AOwner: TFmxObject);
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
  else if ASource = nil then
    Data := nil
  else
    inherited;
end;

constructor TSkAnimatedImage.TSource.Create(const AOnChange: TChangeProc);
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
      FOnChange();
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
  else if (csDesigning in ComponentState) and not Locked then
    FMX.Skia.DrawDesignBorder(ACanvas, ADest, AOpacity);
end;

function TSkAnimatedImage.GetAnimation: TSkAnimatedImage.TAnimation;
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
    FCodec.Quality := Canvas.Quality;
    if (csDesigning in ComponentState) and (not Animation.Running) and (AProgress = 0) then
      FCodec.SeekFrameTime(Animation.Duration / 8)
    else
      FCodec.SeekFrameTime(Animation.CurrentTime);
    ACanvas.Save;
    try
      ACanvas.ClipRect(ADest);
      FCodec.Render(ACanvas, GetWrappedRect(ADest), AOpacity);
    finally
      ACanvas.Restore;
    end;
  end;
  inherited;
end;

procedure TSkAnimatedImage.SetAnimation(const AValue: TSkAnimatedImage.TAnimation);
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

procedure TSkAnimatedImage.SourceChange;
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
{$IF CompilerVersion >= 37}
  Result := GlobalPreferredFramesPerSecond;
{$ELSE}
  Result := TAnimation.DefaultAniFrameRate;
{$ENDIF}
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
  case Quality of
    TCanvasQuality.SystemDefault: ACanvas.DrawImageRect(FAnimationCodec.Frame, ADest, TSkSamplingOptions.Medium, LPaint);
    TCanvasQuality.HighPerformance: ACanvas.DrawImageRect(FAnimationCodec.Frame, ADest, TSkSamplingOptions.Low, LPaint);
    TCanvasQuality.HighQuality: ACanvas.DrawImageRect(FAnimationCodec.Frame, ADest, TSkSamplingOptions.Medium, LPaint);
  end;
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
      Result := TSkottieAnimation.MakeFromStream(LDecompressionStream, TSkDefaultProviders.Resource, TSkDefaultProviders.TypefaceFont);
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
    LSkottie := TSkottieAnimation.MakeFromStream(AStream, TSkDefaultProviders.Resource, TSkDefaultProviders.TypefaceFont);

  Result := Assigned(LSkottie);
  if Result then
    ACodec := TSkLottieAnimationCodec.Create(LSkottie)
  else
    ACodec := nil;
end;

{ TSkFontComponent }

procedure TSkFontComponent.AssignTo(ADest: TPersistent);
var
  LDestFont: TFont absolute ADest;
  {$IF CompilerVersion < 31}
  LStyle: TFontStyles;
  {$ENDIF}
begin
  if ADest is TFont then
  begin
    LDestFont.Family := Families;
    LDestFont.Size := Size;
    {$IF CompilerVersion >= 31}
    LDestFont.StyleExt := TFontStyleExt.Create(Weight, Slant, Stretch);
    {$ELSE}
    LStyle := [];
    if SkFontWeightValue[Weight] >= 600 then
      LStyle := LStyle + [TFontStyle.fsBold];
    if Slant <> TFontSlant.Regular then
      LStyle := LStyle + [TFontStyle.fsItalic];
    LDestFont.Style := LStyle;
    {$ENDIF}
  end
  else
    inherited;
end;

constructor TSkFontComponent.Create;
begin
  inherited Create;
  Assign(nil);
end;

function TSkFontComponent.DefaultFamilies: string;
begin
  Result := '';
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
    Families := TFont(ASource).Family;
    Size     := TFont(ASource).Size;
    {$IF CompilerVersion >= 31}
    Slant    := TFont(ASource).StyleExt.Slant;
    Stretch  := TFont(ASource).StyleExt.Stretch;
    Weight   := TFont(ASource).StyleExt.Weight;
    {$ELSE}
    if TFontStyle.fsItalic in TFont(ASource).Style then
      Slant  := TFontSlant.Italic
    else
      Slant  := TFontSlant.Regular;
    Stretch  := TFontStretch.Regular;
    if TFontStyle.fsBold in TFont(ASource).Style then
      Weight := TFontWeight.Bold
    else
      Weight := TFontWeight.Regular;
    {$ENDIF}
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

procedure TSkFontComponent.SetSlant(const AValue: TFontSlant);
begin
  SetValue<TFontSlant>(FSlant, AValue);
end;

procedure TSkFontComponent.SetStretch(const AValue: TFontStretch);
begin
  SetValue<TFontStretch>(FStretch, AValue);
end;

procedure TSkFontComponent.SetWeight(const AValue: TFontWeight);
begin
  SetValue<TFontWeight>(FWeight, AValue);
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
  const AStyledSettings: TStyledSettings);
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
  FFont := CreateFont;
  FFont.OnChange := FontChanged;
  FDecorations := TDecorations.Create;
  FDecorations.OnChange := DecorationsChange;
  Assign(nil);
end;

function TSkTextSettings.CreateFont: TSkFontComponent;
begin
  Result := TSkFontComponent.Create;
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

  function TextAlignToSkTextHorzAlign(const ATextAlign: TTextAlign): TSkTextHorzAlign;
  begin
    case ATextAlign of
      TTextAlign.Center:
        Result := TSkTextHorzAlign.Center;
      TTextAlign.Leading:
        Result := TSkTextHorzAlign.Leading;
      TTextAlign.Trailing:
        Result := TSkTextHorzAlign.Trailing;
    else
      Result := DefaultHorzAlign;
    end;
  end;

{$IF CompilerVersion < 31}
const
  ItalicToSlant: array[Boolean] of TFontSlant = (TFontSlant.Regular, TFontSlant.Italic);
  BoldToWeight: array[Boolean] of TFontWeight = (TFontWeight.Regular, TFontWeight.Bold);
{$ENDIF}
var
  LFMXTextSettings: TTextSettings absolute ASource;
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
  else if ASource is TTextSettings then
  begin
    Decorations      := nil;
    Font.Families    := LFMXTextSettings.Font.Family;
    Font.Size        := LFMXTextSettings.Font.Size;
    {$IF CompilerVersion >= 31}
    Font.Slant       := LFMXTextSettings.Font.StyleExt.Slant;
    Font.Stretch     := LFMXTextSettings.Font.StyleExt.Stretch;
    Font.Weight      := LFMXTextSettings.Font.StyleExt.Weight;
    {$ELSE}
    Font.Slant       := ItalicToSlant[TFontStyle.fsItalic in LFMXTextSettings.Font.Style];
    Font.Stretch     := TFontStretch.Regular;
    Font.Weight      := BoldToWeight[TFontStyle.fsBold in LFMXTextSettings.Font.Style];
    {$ENDIF}
    FontColor        := LFMXTextSettings.FontColor;
    HeightMultiplier := DefaultHeightMultiplier;
    HorzAlign        := TextAlignToSkTextHorzAlign(LFMXTextSettings.HorzAlign);
    LetterSpacing    := DefaultLetterSpacing;
    MaxLines         := DefaultMaxLines;
    Trimming         := LFMXTextSettings.Trimming;
    VertAlign        := LFMXTextSettings.VertAlign;
  end
  else
    inherited;
end;

procedure TSkTextSettings.DoAssignNotStyled(
  const ATextSettings: TSkTextSettings; const AStyledSettings: TStyledSettings);
begin
  Font.BeginUpdate;
  try
    if not (TStyledSetting.Family in AStyledSettings) then
      Font.Families := ATextSettings.Font.Families;
    if not (TStyledSetting.Size in AStyledSettings) then
      Font.Size := ATextSettings.Font.Size;
    if not (TStyledSetting.Style in AStyledSettings) then
    begin
      Font.Slant   := ATextSettings.Font.Slant;
      Font.Stretch := ATextSettings.Font.Stretch;
      Font.Weight  := ATextSettings.Font.Weight;
    end;
  finally
    Font.EndUpdate;
  end;
  if not (TStyledSetting.FontColor in AStyledSettings) then
    FontColor := ATextSettings.FontColor;
  if not (TStyledSetting.Other in AStyledSettings) then
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

procedure TSkTextSettings.SetTrimming(const AValue: TTextTrimming);
begin
  SetValue<TTextTrimming>(FTrimming, AValue);
end;

procedure TSkTextSettings.SetVertAlign(const AValue: TTextAlign);
begin
  SetValue<TTextAlign>(FVertAlign, AValue);
end;

procedure TSkTextSettings.UpdateStyledSettings(const AOldTextSettings,
  ADefaultTextSettings: TSkTextSettings; var AStyledSettings: TStyledSettings);
begin
  // If the user changed the value of the property, and it differs from the default,
  // then delete the corresponding value from AStyledSettings
  if (not SameText(AOldTextSettings.Font.Families, Font.Families)) and
    (not SameText(ADefaultTextSettings.Font.Families, Font.Families)) then
  begin
    Exclude(AStyledSettings, TStyledSetting.Family);
  end;

  if (not SameValue(AOldTextSettings.Font.Size, Font.Size, TEpsilon.FontSize)) and
    (not SameValue(ADefaultTextSettings.Font.Size, Font.Size, TEpsilon.FontSize)) then
  begin
    Exclude(AStyledSettings, TStyledSetting.Size);
  end;

  if ((AOldTextSettings.Font.Slant <> Font.Slant) or (AOldTextSettings.Font.Stretch <> Font.Stretch) or
    (AOldTextSettings.Font.Weight <> Font.Weight)) and
    ((ADefaultTextSettings.Font.Slant <> Font.Slant) or (ADefaultTextSettings.Font.Stretch <> Font.Stretch) or
    (ADefaultTextSettings.Font.Weight <> Font.Weight)) then
  begin
    Exclude(AStyledSettings, TStyledSetting.Style);
  end;

  if ((AOldTextSettings.FontColor <> FontColor) and (ADefaultTextSettings.FontColor <> FontColor)) then
    Exclude(AStyledSettings, TStyledSetting.FontColor);

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
    Exclude(AStyledSettings, TStyledSetting.Other);
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

procedure TSkTextSettingsInfo.SetStyledSettings(const AValue: TStyledSettings);
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

{ TSkCustomStyleTextObject }

constructor TSkCustomStyleTextObject.Create(AOwner: TComponent);
begin
  inherited;
  FTextSettings := CreateTextSettings;
  FTextSettings.OnChange := TextSettingsChange;
end;

function TSkCustomStyleTextObject.CreateTextSettings: TSkTextSettings;
begin
  Result := TSkTextSettings.Create(Self);
end;

destructor TSkCustomStyleTextObject.Destroy;
begin
  FTextSettings.Free;
  FSavedTextSettings.Free;
  inherited;
end;

function TSkCustomStyleTextObject.GetTextSettings: TSkTextSettings;
begin
  Result := FTextSettings;
end;

function TSkCustomStyleTextObject.RestoreState: Boolean;
begin
  Result := False;
  if (FSavedTextSettings <> nil) and (FTextSettings <> nil) then
  begin
    TextSettings := FSavedTextSettings;
    FreeAndNil(FSavedTextSettings);
    Result := True;
  end;
end;

function TSkCustomStyleTextObject.SaveState: Boolean;
begin
  Result := False;
  if FTextSettings <> nil then
  begin
    if FSavedTextSettings = nil then
      FSavedTextSettings := TSkTextSettingsClass(FTextSettings.ClassType).Create(nil);
    FSavedTextSettings.Assign(FTextSettings);
    Result := True;
  end;
end;

procedure TSkCustomStyleTextObject.SetName(const ANewName: TComponentName);
begin
  inherited;
  if FStyleName = '' then
    FStyleName := Name;
end;

procedure TSkCustomStyleTextObject.SetTextSettings(const AValue: TSkTextSettings);
begin
  FTextSettings.Assign(AValue);
end;

procedure TSkCustomStyleTextObject.TextSettingsChange(ASender: TObject);
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

{$IF CompilerVersion < 29}
procedure ValidateInheritance(const AValue: TPersistent; const AClass: TClass; const CanBeNil: Boolean = True);
const
  SEUseHeirs = 'You can use only the inheritors of class "%s"';
begin
  if (AClass <> nil) and (CanBeNil or (AValue <> nil)) then
  begin
    if (AValue <> nil) and not AValue.InheritsFrom(AClass) then
      raise EArgumentException.CreateFMT(SEUseHeirs, [AClass.ClassName])at ReturnAddress;
  end
  else
    raise EArgumentNilException.Create(SArgumentNil)at ReturnAddress;
end;
{$ENDIF}

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
    Cursor           := DefaultCursor;
    Font             := nil;
    FontColor        := DefaultFontColor;
    HeightMultiplier := DefaultHeightMultiplier;
    LetterSpacing    := DefaultLetterSpacing;
    Name             := UniqueName(DefaultName, Collection);
    StyledSettings   := DefaultStyledSettings;
    Text             := DefaultText;
    OnClick          := nil;
  end
  else if ASource is TCustomWordsItem then
  begin
    BackgroundColor  := LSourceItem.BackgroundColor;
    Cursor           := LSourceItem.Cursor;
    Font             := LSourceItem.Font;
    FontColor        := LSourceItem.FontColor;
    HeightMultiplier := LSourceItem.HeightMultiplier;
    LetterSpacing    := LSourceItem.LetterSpacing;
    Name             := UniqueName(LSourceItem.Name, Collection);
    StyledSettings   := LSourceItem.StyledSettings;
    Text             := LSourceItem.Text;
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

function TSkLabel.TCustomWordsItem.GetStyledSettings: TStyledSettings;
begin
  Result := FTextSettingsInfo.StyledSettings;
end;

function TSkLabel.TCustomWordsItem.IsFontColorStored: Boolean;
begin
  Result := (FontColor <> DefaultFontColor) or not (TStyledSetting.FontColor in StyledSettings);
end;

function TSkLabel.TCustomWordsItem.IsHeightMultiplierStored: Boolean;
begin
  Result := (not SameValue(HeightMultiplier, DefaultHeightMultiplier, TEpsilon.Position)) or not (TStyledSetting.Other in StyledSettings);
end;

function TSkLabel.TCustomWordsItem.IsLetterSpacingStored: Boolean;
begin
  Result := (not SameValue(LetterSpacing, DefaultLetterSpacing, TEpsilon.Position)) or not (TStyledSetting.Other in StyledSettings);
end;

function TSkLabel.TCustomWordsItem.IsNameStored: Boolean;
begin
  Result := (Assigned(Collection) and (Collection.Count <> 1)) or (Name <> 'Item 0');
end;

function TSkLabel.TCustomWordsItem.IsStyledSettingsStored: Boolean;
begin
  Result := StyledSettings <> DefaultStyledSettings;
end;

function TSkLabel.TCustomWordsItem.IsTextStored: Boolean;
begin
  Result := Text <> DefaultText;
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

procedure TSkLabel.TCustomWordsItem.SetCollection(AValue: TCollection);
var
  S: string;
begin
  ValidateInheritance(AValue, TWordsCollection);
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
  const AValue: TStyledSettings);
begin
  FTextSettingsInfo.StyledSettings := AValue;
end;

procedure TSkLabel.TCustomWordsItem.SetText(const AValue: string);
begin
  if FText <> AValue then
  begin
    FText := AValue;
    Change;
  end;
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

function TSkLabel.TWordsCollection.Add(const AText: string;
  const AColor: TAlphaColor; const AFontSize: Single;
  const AFontWeight: TFontWeight;
  const AFontSlant: TFontSlant): TCustomWordsItem;
begin
  Result := Add;
  Result.BeginUpdate;
  try
    Result.Text := AText;
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

function TSkLabel.TWordsCollection.AddOrSet(const AName, AText: string;
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
    Result.Font := AFont;
    Result.FontColor := AFontColor;
    Result.Text := AText;
    Result.OnClick := AOnClick;
    Result.Cursor := ACursor;
  finally
    Result.EndUpdate;
  end;
end;

constructor TSkLabel.TWordsCollection.Create(AOwner: TPersistent;
  AItemClass: TCustomWordsItemClass);
begin
  ValidateInheritance(AOwner, TSkLabel, False);
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

procedure TSkLabel.ApplyStyle;
var
  LFontBehavior: IFontBehavior;

  procedure SetupDefaultTextSetting(const AObject: TFmxObject;
    const ADefaultTextSettings: TSkTextSettings);
  var
    LFMXTextSettings: ITextSettings;
    LNewFamily: string;
    LNewSize: Single;
  begin
    if (AObject <> nil) and AObject.GetInterface(IObjectState, FObjectState) then
      FObjectState.SaveState
    else
      FObjectState := nil;

    FStyleText := nil;
    if ADefaultTextSettings <> nil then
    begin
      if Supports(AObject, ISkStyleTextObject, FStyleText) then
        ADefaultTextSettings.Assign(FStyleText.TextSettings)
      else if Supports(AObject, ITextSettings, LFMXTextSettings) then
        ADefaultTextSettings.Assign(LFMXTextSettings.TextSettings)
      else
        ADefaultTextSettings.Assign(nil);

      if LFontBehavior <> nil then
      begin
        LNewFamily := '';
        LFontBehavior.GetDefaultFontFamily(Scene.GetObject, LNewFamily);
        if not LNewFamily.IsEmpty then
          ADefaultTextSettings.Font.Families := LNewFamily;

        LNewSize := 0;
        LFontBehavior.GetDefaultFontSize(Scene.GetObject, LNewSize);
        if not SameValue(LNewSize, 0, TEpsilon.FontSize) then
          ADefaultTextSettings.Font.Size := LNewSize;
      end;
    end;
  end;

var
  LInterface: IInterface;
  LNewText: string;
  LTextResource: TFmxObject;
  I: Integer;
begin
  LFontBehavior := nil;
  BeginUpdate;
  try
    ResultingTextSettings.BeginUpdate;
    try
      FTextSettingsInfo.Design := False;
      { behavior }
      if (Scene <> nil) and TBehaviorServices.Current.SupportsBehaviorService(IFontBehavior, LInterface, Scene.GetObject) then
        Supports(LInterface, IFontBehavior, LFontBehavior);

      if Supports(ResourceLink, ISkStyleTextObject) then
        LTextResource := ResourceLink
      else
        LTextResource := FindStyleResource('text');

      { from text }
      SetupDefaultTextSetting(LTextResource, FTextSettingsInfo.DefaultTextSettings);
      inherited;
      ResultingTextSettings.Change;
    finally
      ResultingTextSettings.EndUpdate;
      FTextSettingsInfo.Design := True;//csDesigning in ComponentState;
    end;
    if AutoTranslate and not Text.IsEmpty then
    begin
      for I := 0 to FWords.Count - 1 do
      begin
        LNewText := Translate(FWords[I].Text); // need for collection texts
        if not (csDesigning in ComponentState) then
          FWords[I].Text := LNewText;
      end;
    end;
    DeleteParagraph;
    if (not IsUpdating) and FAutoSize and HasFitSizeChanged then
      SetSize(Width, Height);
    Redraw;
  finally
    EndUpdate;
  end;
end;

procedure TSkLabel.Click;
var
  LClickedItem: TCustomWordsItem;
begin
  LClickedItem := GetWordsItemAtPosition(FClickedPosition.X, FClickedPosition.Y);
  if Assigned(LClickedItem) and (LClickedItem = GetWordsItemAtPosition(PressedPosition.X, PressedPosition.Y)) then
  begin
    TMessageManager.DefaultManager.SendMessage(Self, TItemClickedMessage.Create(LClickedItem));
    if Assigned(LClickedItem.OnClick) then
      LClickedItem.OnClick(LClickedItem)
    else
      inherited;
  end
  else
    inherited;
end;

constructor TSkLabel.Create(AOwner: TComponent);
begin
  inherited;
  SetAcceptsControls(False);
  FAutoSize := True;
  AutoTranslate := True;
  FTextSettingsInfo := TSkTextSettingsInfo.Create(Self, nil);
  FTextSettingsInfo.Design := True;//csDesigning in ComponentState;
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

function TSkLabel.DidExceedMaxLines: Boolean;
var
  LParagraph: ISkParagraph;
begin
  LParagraph := Paragraph;
  Result := Assigned(LParagraph) and (LParagraph.DidExceedMaxLines);
end;

procedure TSkLabel.DoEndUpdate;
begin
  if (not (csLoading in ComponentState)) and FAutoSize and HasFitSizeChanged then
    SetSize(Width, Height)
  else
    inherited;
end;

procedure TSkLabel.DoMouseEnter;
begin
  FLastMousePosition := PointF(-1, -1);
  inherited;
end;

procedure TSkLabel.DoMouseLeave;
begin
  inherited;
  UpdateWordsMouseOver;
end;

function TSkLabel.DoSetSize(const ASize: TControlSize;
  const ANewPlatformDefault: Boolean; ANewWidth, ANewHeight: Single;
  var ALastWidth, ALastHeight: Single): Boolean;
begin
  if FAutoSize and not (csLoading in ComponentState) then
    GetFitSize(ANewWidth, ANewHeight);
  Result := inherited;
end;

procedure TSkLabel.DoStyleChanged;
var
  LNewText: string;
  I: Integer;
begin
  inherited;
  if AutoTranslate and not Text.IsEmpty then
  begin
    for I := 0 to FWords.Count - 1 do
    begin
      LNewText := Translate(FWords[I].Text); // need for collection texts
      if not (csDesigning in ComponentState) then
        FWords[I].Text := LNewText;
    end;
  end;
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
      Inc(LTextEndIndex, FWords[I].Text.Length);
      if TAlphaColorRec(FWords[I].BackgroundColor).A = 0 then
        Continue;
      for LTextBox in AParagraph.GetRectsForRange(LTextEndIndex - FWords[I].Text.Length, LTextEndIndex, TSkRectHeightStyle.Tight, TSkRectWidthStyle.Tight) do
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
      LCanvas.DrawRoundRect(LRects[I], 2, 2, LPaint);
    end;
    Result := LPictureRecorder.FinishRecording;
  end;

var
  LParagraph: ISkParagraph;
  LPositionY: Single;
begin
  if FLastFillTextFlags <> FillTextFlags then
    DeleteParagraph;
  LParagraph := Paragraph;
  if Assigned(LParagraph) then
  begin
    ParagraphLayout(ADest.Width);
    LPositionY := ADest.Top;
    case ResultingTextSettings.VertAlign of
      TTextAlign.Center: LPositionY := LPositionY + ((ADest.Height - ParagraphBounds.Height) / 2);
      TTextAlign.Leading: ;
      TTextAlign.Trailing: LPositionY := LPositionY + (ADest.Height - ParagraphBounds.Height);
    end;

    if SameValue(AOpacity, 1, TEpsilon.Position) then
      ACanvas.Save
    else
      ACanvas.SaveLayerAlpha(Round(AOpacity * 255));
    try
      ACanvas.ClipRect(ADest);
      ACanvas.Translate(ADest.Left, LPositionY);
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

function TSkLabel.FillTextFlags: TFillTextFlags;
begin
  Result := inherited;
  if (Root = nil) and (Application.BiDiMode = TBiDiMode.bdRightToLeft) then
    Result := Result + [TFillTextFlag.RightToLeft];
end;

procedure TSkLabel.FreeStyle;
begin
  if FObjectState <> nil then
  begin
    FObjectState.RestoreState;
    FObjectState := nil;
  end;
  FStyleText := nil;
  inherited;
end;

function TSkLabel.GetDefaultSize: TSizeF;
{$IF CompilerVersion >= 30}
var
  LDeviceInfo: IDeviceBehavior;
{$ENDIF}
begin
  {$IF CompilerVersion >= 30}
  if TBehaviorServices.Current.SupportsBehaviorService(IDeviceBehavior, LDeviceInfo, Self) then
    case LDeviceInfo.GetOSPlatform(Self) of
      TOSPlatform.Windows: Result := TSizeF.Create(120, 19);
      TOSPlatform.OSX: Result := TSizeF.Create(120, 19);
      TOSPlatform.iOS: Result := TSize.Create(82, 21);
      TOSPlatform.Android: Result := TSize.Create(82, 23);
      {$IF CompilerVersion >= 34}
      TOSPlatform.Linux: Result := TSizeF.Create(120, 19);
      {$ENDIF}
    end
  else
  {$ENDIF}
    Result := TSizeF.Create(120, 19);
end;

{$IF CompilerVersion > 36}
function TSkLabel.GetDefaultStyleLookupName: string;
begin
  Result := 'labelstyle';
end;
{$ENDIF}

function TSkLabel.GetDefaultTextSettings: TSkTextSettings;
begin
  Result := FTextSettingsInfo.DefaultTextSettings;
end;

procedure TSkLabel.GetFitSize(var AWidth, AHeight: Single);

  function GetFitHeight: Single;
  begin
    case Align of
      TAlignLayout.Client,
      TAlignLayout.Contents,
      TAlignLayout.Left,
      TAlignLayout.MostLeft,
      TAlignLayout.Right,
      TAlignLayout.MostRight,
      TAlignLayout.FitLeft,
      TAlignLayout.FitRight,
      TAlignLayout.HorzCenter,
      TAlignLayout.Vertical: Result := AHeight;
    else
      Result := ParagraphBounds.Height;
    end;
  end;

  function GetFitWidth: Single;
  begin
    case Align of
      TAlignLayout.Client,
      TAlignLayout.Contents,
      TAlignLayout.Top,
      TAlignLayout.MostTop,
      TAlignLayout.Bottom,
      TAlignLayout.MostBottom,
      TAlignLayout.VertCenter,
      TAlignLayout.Horizontal: Result := AWidth;
    else
      Result := ParagraphBounds.Width;
    end;
  end;

var
  LParagraph: ISkParagraph;
begin
  LParagraph := Paragraph;
  if Assigned(LParagraph) then
  begin
    if Align in [TAlignLayout.Top, TAlignLayout.MostTop, TAlignLayout.Bottom,
      TAlignLayout.MostBottom, TAlignLayout.VertCenter, TAlignLayout.Horizontal] then
    begin
      ParagraphLayout(AWidth);
    end
    else
      ParagraphLayout(Infinity);
  end;
  try
    AWidth := GetFitWidth;
    AHeight := GetFitHeight;
  finally
    if Assigned(LParagraph) then
      ParagraphLayout(AWidth);
  end;
end;

function TSkLabel.GetLinesCount: Integer;
var
  LParagraph: ISkParagraph;
begin
  LParagraph := Paragraph;
  if Assigned(LParagraph) then
    Result := Length(LParagraph.LineMetrics)
  else
    Result := 0;
end;

function TSkLabel.GetParagraph: ISkParagraph;
type
  TDrawKind = (Fill, Stroke);
var
  LFontBehavior: IFontBehavior;
  LHasTextStroked: Boolean;

  function GetFontFamilies(const AValue: string): TArray<string>;
  var
    LInterface: IInterface;
  begin
    Result := AValue.Split([', ', ','], TStringSplitOptions.ExcludeEmpty);
    if Result = nil then
    begin
      if (LFontBehavior = nil) and (Scene <> nil) and TBehaviorServices.Current.SupportsBehaviorService(IFontBehavior, LInterface, Scene.GetObject) then
        Supports(LInterface, IFontBehavior, LFontBehavior);
      if Assigned(LFontBehavior) then
      begin
        SetLength(Result, 1);
        Result[0] := '';
        LFontBehavior.GetDefaultFontFamily(Scene.GetObject, Result[0]);
        if Result[0].IsEmpty then
          Result := [];
      end;
    end;
    {$IFDEF MACOS}
    Result := Result + ['Helvetica Neue'];
    {$ELSEIF DEFINED(LINUX)}
    Result := Result + ['Ubuntu'];
    {$ENDIF}
  end;

  function GetFontSize(const AValue: Single): Single;
  var
    LInterface: IInterface;
  begin
    Result := AValue;
    if SameValue(AValue, 0, TEpsilon.FontSize) then
    begin
      if (LFontBehavior = nil) and (Scene <> nil) and TBehaviorServices.Current.SupportsBehaviorService(IFontBehavior, LInterface, Scene.GetObject) then
        Supports(LInterface, IFontBehavior, LFontBehavior);
      if Assigned(LFontBehavior) then
        LFontBehavior.GetDefaultFontSize(Scene.GetObject, Result);
    end;
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
    const ADefaultTextStyle: ISkTextStyle;
    const ADrawKind: TDrawKind): ISkTextStyle;
  begin
    Result := TSkTextStyle.Create;
    if TStyledSetting.FontColor in AWordsItem.StyledSettings then
      Result.Color := ResultingTextSettings.FontColor
    else
      Result.Color := AWordsItem.FontColor;
    if TStyledSetting.Family in AWordsItem.StyledSettings then
      Result.FontFamilies := ADefaultTextStyle.FontFamilies
    else
      Result.FontFamilies := GetFontFamilies(AWordsItem.Font.Families);
    if TStyledSetting.Size in AWordsItem.StyledSettings then
      Result.FontSize := ADefaultTextStyle.FontSize
    else
      Result.FontSize := GetFontSize(AWordsItem.Font.Size);
    if TStyledSetting.Style in AWordsItem.StyledSettings then
      Result.FontStyle := ADefaultTextStyle.FontStyle
    else
      Result.FontStyle := TSkFontStyle.Create(SkFontWeightValue[AWordsItem.Font.Weight], SkFontWidthValue[AWordsItem.Font.Stretch], SkFontSlant[AWordsItem.Font.Slant]);
    if TStyledSetting.Other in AWordsItem.StyledSettings then
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
    if GlobalSkiaTextLocale <> '' then
      Result.Locale := GlobalSkiaTextLocale;
  end;

  function CreateDefaultTextStyle(const ADrawKind: TDrawKind): ISkTextStyle;
  begin
    Result := TSkTextStyle.Create;
    Result.Color := ResultingTextSettings.FontColor;
    Result.FontFamilies := GetFontFamilies(ResultingTextSettings.Font.Families);
    Result.FontSize := GetFontSize(ResultingTextSettings.Font.Size);
    Result.FontStyle := TSkFontStyle.Create(SkFontWeightValue[ResultingTextSettings.Font.Weight], SkFontWidthValue[ResultingTextSettings.Font.Stretch], SkFontSlant[ResultingTextSettings.Font.Slant]);
    Result.HeightMultiplier := ResultingTextSettings.HeightMultiplier;
    Result.LetterSpacing := ResultingTextSettings.LetterSpacing;
    SetTextStyleDecorations(Result, ResultingTextSettings.Decorations, ADrawKind);
    if GlobalSkiaTextLocale <> '' then
      Result.Locale := GlobalSkiaTextLocale;
  end;

  function CreateParagraphStyle(const ADefaultTextStyle: ISkTextStyle): ISkParagraphStyle;
  const
    SkTextAlign: array[TSkTextHorzAlign] of TSkTextAlign = (TSkTextAlign.Center, TSkTextAlign.Start, TSkTextAlign.Terminate, TSkTextAlign.Justify);
  begin
    Result := TSkParagraphStyle.Create;
    FLastFillTextFlags := FillTextFlags;
    if TFillTextFlag.RightToLeft in FLastFillTextFlags then
      Result.TextDirection := TSkTextDirection.RightToLeft;
    if ResultingTextSettings.Trimming in [TTextTrimming.Character, TTextTrimming.Word] then
      Result.Ellipsis := '...';
    if (ResultingTextSettings.MaxLines <= 0) or (ResultingTextSettings.MaxLines = High(NativeUInt)) then
      Result.MaxLines := High(NativeUInt) - 1
    else
      Result.MaxLines := ResultingTextSettings.MaxLines;
    Result.TextAlign := SkTextAlign[ResultingTextSettings.HorzAlign];
    Result.TextStyle := ADefaultTextStyle;
  end;

  function CreateParagraph(const ADrawKind: TDrawKind): ISkParagraph;
  var
    LBuilder: ISkParagraphBuilder;
    LDefaultTextStyle: ISkTextStyle;
    LText: string;
    I: Integer;
  begin
    LFontBehavior := nil;
    LDefaultTextStyle := CreateDefaultTextStyle(ADrawKind);
    LBuilder := TSkParagraphBuilder.Create(CreateParagraphStyle(LDefaultTextStyle), TSkDefaultProviders.TypefaceFont);
    for I := 0 to FWords.Count- 1 do
    begin
      if FWords[I].Text = '' then
        Continue;
      if FWords[I].StyledSettings = AllStyledSettings then
        LBuilder.AddText(FWords[I].Text)
      else
      begin
        LText := NormalizeParagraphText(FWords[I].Text);
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
  if (FParagraph = nil) and (Text <> '') then
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
      Result := RectF(0, 0, LParagraph.MaxIntrinsicWidth, LParagraph.Height)
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

function TSkLabel.GetStyledSettings: TStyledSettings;
begin
  Result := FTextSettingsInfo.StyledSettings;
end;

function TSkLabel.GetText: string;
var
  I: Integer;
begin
  Result := '';
  if Assigned(FWords) and (FWords.Count > 0) then
    for I := 0 to FWords.Count - 1 do
      Result := Result + FWords[I].Text;
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
  AY: Single): TCustomWordsItem;

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
      TTextAlign.Center: LParagraphPoint := PointF(AX, AY - (Height - ParagraphBounds.Height) / 2);
      TTextAlign.Trailing: LParagraphPoint := PointF(AX, AY - Height - ParagraphBounds.Height);
    else
      LParagraphPoint := PointF(AX, AY);
    end;
    LTextIndex := 0;
    for I := 0 to FWords.Count - 1 do
    begin
      if FWords[I].Text.Length = 0 then
        Continue;
      LTextBoxes := LParagraph.GetRectsForRange(LTextIndex, LTextIndex + FWords[I].Text.Length, TSkRectHeightStyle.Max, TSkRectWidthStyle.Tight);
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
      Inc(LTextIndex, FWords[I].Text.Length);
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

function TSkLabel.IsStyledSettingsStored: Boolean;
begin
  Result := StyledSettings <> DefaultStyledSettings;
end;

procedure TSkLabel.Loaded;
begin
  inherited;
  if (not IsUpdating) and FAutoSize and HasFitSizeChanged then
    SetSize(Width, Height);
end;

procedure TSkLabel.MouseClick(AButton: TMouseButton; AShift: TShiftState; AX,
  AY: Single);
begin
  FClickedPosition := PointF(AX, AY);
  FLastMousePosition := FClickedPosition;
  inherited;
  UpdateWordsMouseOver;
end;

{$IF CompilerVersion < 30}
procedure TSkLabel.MouseDown(AButton: TMouseButton; AShift: TShiftState; AX, AY: Single);
begin
  inherited;
  if AButton = TMouseButton.mbLeft then
    FPressedPosition := TPointF.Create(AX, AY);
end;
{$ENDIF}

procedure TSkLabel.MouseMove(AShift: TShiftState; AX, AY: Single);
begin
  FLastMousePosition := PointF(AX, AY);
  if FHasCustomCursor then
    UpdateWordsMouseOver;
  inherited;
end;

function TSkLabel.NeedsRedraw: Boolean;
begin
  Result := inherited or (FLastFillTextFlags <> FillTextFlags);
end;

function TSkLabel.NormalizeParagraphText(const AText: string): string;
const
  // Ideographic space is similar to tab character as it has the size of two white spaces usually
  IdeographicSpace = Char($3000);
begin
  // Temporary solution for version m107, that have a know issue with tab character that are rendering as a square.
  // https://github.com/skia4delphi/skia4delphi/issues/270
  // https://issues.skia.org/issues/40043415
  Result := AText.Replace(#09, IdeographicSpace);

  // Temporary solution to fix an issue with Skia:
  // https://bugs.chromium.org/p/skia/issues/detail?id=13117
  // SkParagraph has several issues with the #13 line break, so the best thing
  // to do is replace it with #10 or a zero-widh character (#8203)
  Result := Result.Replace(#13#10, #8203#10).Replace(#13, #10);
end;

procedure TSkLabel.ParagraphLayout(AMaxWidth: Single);

  function DoParagraphLayout(const AParagraph: ISkParagraph; const AMaxWidth: Single): Single;
  begin
    if CompareValue(AMaxWidth, 0, TEpsilon.Position) = GreaterThanValue then
    begin
      if IsInfinite(AMaxWidth) then
        Result := AMaxWidth
      else
        // The SkParagraph.Layout calls a floor for the MaxWidth, so we should ceil it to force the original AMaxWidth
        Result := CeilFloat(AMaxWidth + TEpsilon.Matrix);
    end
    else
      Result := 0;
    AParagraph.Layout(Result);
  end;

var
  LMaxWidthUsed: Single;
  LParagraph: ISkParagraph;
begin
  AMaxWidth := Max(AMaxWidth, 0);
  if not SameValue(FParagraphLayoutWidth, AMaxWidth, TEpsilon.Position) then
  begin
    LParagraph := Paragraph;
    if Assigned(LParagraph) then
    begin
      LMaxWidthUsed := DoParagraphLayout(LParagraph, AMaxWidth);
      if Assigned(FParagraphStroked) then
        FParagraphStroked.Layout(LMaxWidthUsed);
      FParagraphLayoutWidth := AMaxWidth;
      FParagraphBounds := TRectF.Empty;
      FBackgroundPicture := nil;
    end;
  end;
end;

procedure TSkLabel.SetAlign(const AValue: TAlignLayout);
begin
  if (Align <> AValue) and AutoSize then
  begin
    inherited;
    SetSize(Width, Height);
  end
  else
    inherited;
end;

procedure TSkLabel.SetAutoSize(const AValue: Boolean);
begin
  if FAutoSize <> AValue then
  begin
    FAutoSize := AValue;
    SetSize(Width, Height);
  end;
end;

procedure TSkLabel.SetName(const AValue: TComponentName);
var
  LChangeText: Boolean;
begin
  LChangeText := not (csLoading in ComponentState) and (Name = Text) and
    ((Owner = nil) or not (csLoading in TComponent(Owner).ComponentState));
  inherited SetName(AValue);
  if LChangeText then
    Text := AValue;
end;

procedure TSkLabel.SetStyledSettings(const AValue: TStyledSettings);
begin
  FTextSettingsInfo.StyledSettings := AValue;
end;

procedure TSkLabel.SetText(const AValue: string);
begin
  if Assigned(FWords) then
  begin
    FWords.BeginUpdate;
    try
      if FWords.Count = 1 then
        FWords[0].Text := AValue
      else
      begin
        FWords.Clear;
        FWords.Add.Text := AValue;
      end;
    finally
      FWords.EndUpdate;
    end;
  end;
end;

procedure TSkLabel.SetTextSettings(const AValue: TSkTextSettings);
begin
  FTextSettingsInfo.TextSettings := AValue;
end;

procedure TSkLabel.SetWords(const AValue: TWordsCollection);
begin
  FWords.Assign(AValue);
end;

procedure TSkLabel.TextSettingsChanged(AValue: TObject);
begin
  DeleteParagraph;
  if not (csLoading in ComponentState) then
  begin
    if (not IsUpdating) and FAutoSize and HasFitSizeChanged then
      SetSize(Width, Height)
    else
      Redraw;
  end;
  UpdateWordsMouseOver;
end;

procedure TSkLabel.UpdateWordsMouseOver;

  procedure SetWordsMouseOver(const AValue: TCustomWordsItem);
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

begin
  if FHasCustomCursor and IsMouseOver then
    SetWordsMouseOver(GetWordsItemAtPosition(FLastMousePosition.X, FLastMousePosition.Y))
  else
    SetWordsMouseOver(nil);
end;

{$IF CompilerVersion >= 29}
function TSkLabel.TextStored: Boolean;
begin
  Result := Text <> '';
end;
{$ENDIF}

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

{$IF CompilerVersion >= 36}

{ TSkFontManagerService }

function TSkFontManagerService.AddCustomFontFromFile(const AFileName: TFileName): Boolean;
var
  LTypeface: ISkTypeface;
begin
  LTypeface := TSkTypeFace.MakeFromFile(AFileName);
  Result := LTypeface <> nil;
  if Result then
    RegisterTypeFace(LTypeface)
  else
    Log.d(SCannotFindFontFile, [AFileName]);
  if FOriginalService <> nil then
    FOriginalService.AddCustomFontFromFile(AFileName);
end;

function TSkFontManagerService.AddCustomFontFromResource(const AResourceName: string): Boolean;
var
  LResStream: TResourceStream;
begin
  if FindResource(HInstance, PChar(AResourceName), RT_RCDATA) <> 0 then
  begin
    LResStream := TResourceStream.Create(HInstance, AResourceName, RT_RCDATA);
    try
      Result := AddCustomFontFromStream(LResStream);
    finally
      LResStream.Free;
    end;
  end
  else
  begin
    Log.d(SCannotFindFontResource, [AResourceName]);
    Result := False;
  end;
  if FOriginalService <> nil then
    FOriginalService.AddCustomFontFromResource(AResourceName);
end;

function TSkFontManagerService.AddCustomFontFromStream(const AStream: TStream): Boolean;
var
  LOriginalStreamPosition: Int64;
  LTypeface: ISkTypeface;
begin
  LOriginalStreamPosition := AStream.Position;
  LTypeface := TSkTypeFace.MakeFromStream(AStream);
  Result := LTypeface <> nil;
  if Result then
    RegisterTypeFace(LTypeface);
  if FOriginalService <> nil then
  begin
    AStream.Position := LOriginalStreamPosition;
    FOriginalService.AddCustomFontFromStream(AStream);
  end;
end;

procedure TSkFontManagerService.AddFamilyName(const AFamilyName: string);
var
  LFontInfo: TFontInfo;
begin
  LFontInfo.FamilyName := AFamilyName;
  FFontInfos.Add(LFontInfo);
  FFontFamilyNames.AddOrSetValue(AFamilyName.ToLower, AFamilyName);
end;

constructor TSkFontManagerService.Create;
begin
  inherited Create;
  FFontFamilyNames := TDictionary<TFontName, TFontName>.Create;
  FFontInfos := TList<TFontInfo>.Create;
  TPlatformServices.Current.SupportsPlatformService(IFMXFontManagerService, FOriginalService);
end;

destructor TSkFontManagerService.Destroy;
begin
  FreeAndNil(FFontInfos);
  FreeAndNil(FFontFamilyNames);
  inherited;
end;

function TSkFontManagerService.HasCustomFont(const AFontFamily: TFontName): Boolean;
begin
  Result := FFontFamilyNames.ContainsKey(string(AFontFamily).ToLower);
end;

function TSkFontManagerService.HasCustomFonts: Boolean;
begin
  Result := FFontInfos.Count > 0;
end;

function TSkFontManagerService.GetCustomFontInfo(const AIndex: Integer): TFontInfo;
begin
  Result := FFontInfos[AIndex];
end;

function TSkFontManagerService.GetCustomFontInfoCount: Integer;
begin
  Result := FFontInfos.Count;
end;

procedure TSkFontManagerService.RegisterTypeface(const ATypeface: ISkTypeface);
begin
  inherited;
  AddFamilyName(ATypeface.FamilyName);
end;

procedure TSkFontManagerService.RegisterTypeface(const ATypeface: ISkTypeface; const AFamilyName: string);
begin
  inherited;
  AddFamilyName(ATypeface.FamilyName);
  AddFamilyName(AFamilyName);
end;

{$ENDIF}

{ TSkDefaultProviders }

class constructor TSkDefaultProviders.Create;
begin
  {$IF CompilerVersion >= 36}
  FTypefaceFont := TSkFontManagerService.Create;
  TPlatformServices.Current.RemovePlatformService(IFMXFontManagerService);
  TPlatformServices.Current.AddPlatformService(IFMXFontManagerService, FTypefaceFont);
  {$ELSE}
  FTypefaceFont := TSkTypefaceFontProvider.Create;
  {$ENDIF}
end;

class destructor TSkDefaultProviders.Destroy;
begin
  {$IF CompilerVersion >= 36}
  TPlatformServices.Current.RemovePlatformService(IFMXFontManagerService);
  {$ENDIF}
end;

class procedure TSkDefaultProviders.RegisterTypeface(const AFileName: string);
begin
  FTypefaceFont.RegisterTypeface(TSkTypeFace.MakeFromFile(AFileName));
end;

class procedure TSkDefaultProviders.RegisterTypeface(const AStream: TStream);
begin
  FTypefaceFont.RegisterTypeface(TSkTypeFace.MakeFromStream(AStream));
end;

{ TSkTypefaceManager }

class function TSkTypefaceManager.Provider: ISkTypefaceFontProvider;
begin
  Result := TSkDefaultProviders.TypefaceFont;
end;

class procedure TSkTypefaceManager.RegisterTypeface(const AFileName: string);
begin
  TSkDefaultProviders.RegisterTypeface(AFileName);
end;

class procedure TSkTypefaceManager.RegisterTypeface(const AStream: TStream);
begin
  TSkDefaultProviders.RegisterTypeface(AStream);
end;

{$IFDEF MSWINDOWS}
  {$HPPEMIT '#ifdef USEPACKAGES'}
  {$HPPEMIT '  #pragma link "Skia.Package.FMX.bpi"'}
  {$HPPEMIT '#elif defined(__WIN32__)'}
  {$HPPEMIT '  #pragma link "Skia.Package.FMX.lib"'}
  {$HPPEMIT '#elif defined(_WIN64)'}
  {$HPPEMIT '  #if (__clang_major__ >= 15)'}
  {$HPPEMIT '    #pragma link "Skia.Package.FMX.lib"'}
  {$HPPEMIT '  #else'}
  {$HPPEMIT '    #pragma link "Skia.Package.FMX.a"'}
  {$HPPEMIT '  #endif'}
  {$HPPEMIT '#endif'}
{$ENDIF}

{$IF DEFINED(IOS) or DEFINED(ANDROID)}
  {$HPPEMIT LINKUNIT}
{$ELSEIF DEFINED(MSWINDOWS)}
  {$HPPEMIT '#pragma link "FMX.Skia"'}
{$ENDIF}

{$HPPEMIT NOUSINGNAMESPACE}
{$HPPEMIT END '#if !defined(DELPHIHEADER_NO_IMPLICIT_NAMESPACE_USE) && !defined(NO_USING_NAMESPACE_FMX_SKIA)'}
{$HPPEMIT END '    using ::Fmx::Skia::_di_ISkStyleTextObject;'}
{$HPPEMIT END '    using ::Fmx::Skia::_di_ISkTextSettings;'}
{$HPPEMIT END '    using ::Fmx::Skia::_di_TSkAnimationDrawProc;'}
{$HPPEMIT END '    using ::Fmx::Skia::_di_TSkDrawProc;'}
{$HPPEMIT END '    using ::Fmx::Skia::ESkBitmapHelper;'}
{$HPPEMIT END '    using ::Fmx::Skia::ESkFMX;'}
{$HPPEMIT END '    using ::Fmx::Skia::ESkLabel;'}
{$HPPEMIT END '    using ::Fmx::Skia::ESkPersistentData;'}
{$HPPEMIT END '    using ::Fmx::Skia::ESkTextSettingsInfo;'}
{$HPPEMIT END '    using ::Fmx::Skia::ISkStyleTextObject;'}
{$HPPEMIT END '    using ::Fmx::Skia::ISkTextSettings;'}
{$HPPEMIT END '    using ::Fmx::Skia::TSkAnimatedImage;'}
{$HPPEMIT END '    using ::Fmx::Skia::TSkAnimatedImageWrapMode;'}
{$HPPEMIT END '    using ::Fmx::Skia::TSkAnimatedPaintBox;'}
{$HPPEMIT END '    using ::Fmx::Skia::TSkAnimationDrawEvent;'}
{$HPPEMIT END '    using ::Fmx::Skia::TSkAnimationDrawProc;'}
{$HPPEMIT END '    using ::Fmx::Skia::TSkCustomAnimatedControl;'}
{$HPPEMIT END '    using ::Fmx::Skia::TSkCustomAnimation;'}
{$HPPEMIT END '    using ::Fmx::Skia::TSkCustomControl;'}
{$HPPEMIT END '    using ::Fmx::Skia::TSkCustomStyleTextObject;'}
{$HPPEMIT END '    using ::Fmx::Skia::TSkDefaultProviders;'}
{$HPPEMIT END '    using ::Fmx::Skia::TSkDrawCacheKind;'}
{$HPPEMIT END '    using ::Fmx::Skia::TSkDrawEvent;'}
{$HPPEMIT END '    using ::Fmx::Skia::TSkDrawProc;'}
{$HPPEMIT END '    using ::Fmx::Skia::TSkFontComponent;'}
{$HPPEMIT END '    using ::Fmx::Skia::TSkLabel;'}
{$HPPEMIT END '    using ::Fmx::Skia::TSkPaintBox;'}
{$HPPEMIT END '    using ::Fmx::Skia::TSkPersistent;'}
{$HPPEMIT END '    using ::Fmx::Skia::TSkStyledControl;'}
{$HPPEMIT END '    using ::Fmx::Skia::TSkStyleTextObject;'}
{$HPPEMIT END '    using ::Fmx::Skia::TSkSvg;'}
{$HPPEMIT END '    using ::Fmx::Skia::TSkSvgBrush;'}
{$HPPEMIT END '    using ::Fmx::Skia::TSkSvgSource;'}
{$HPPEMIT END '    using ::Fmx::Skia::TSkSvgWrapMode;'}
{$HPPEMIT END '    using ::Fmx::Skia::TSkTextHorzAlign;'}
{$HPPEMIT END '    using ::Fmx::Skia::TSkTextSettings;'}
{$HPPEMIT END '    using ::Fmx::Skia::TSkTextSettingsClass;'}
{$HPPEMIT END '    using ::Fmx::Skia::TSkTextSettingsInfo;'}
{$HPPEMIT END '    using ::Fmx::Skia::TSkTypefaceManager;'}
{$HPPEMIT END '    using ::Fmx::Skia::SkSupportedPlatformsMask;'}
{$HPPEMIT END '    using ::Fmx::Skia::GlobalDisableSkiaCodecsReplacement;'}
{$HPPEMIT END '    using ::Fmx::Skia::GlobalUseSkia;'}
{$HPPEMIT END '    using ::Fmx::Skia::GlobalUseSkiaRasterWhenAvailable;'}
{$IF CompilerVersion >= 36}
{$HPPEMIT END '    using ::Fmx::Skia::GlobalUseSkiaFilters;'}
{$HPPEMIT END '    using ::Fmx::Skia::GlobalSkiaBitmapsInParallel;'}
{$ENDIF}
{$HPPEMIT END '    using ::Fmx::Skia::GlobalSkiaTextLocale;'}
{$HPPEMIT END '    using ::Fmx::Skia::SkFmxColorType;'}
{$HPPEMIT END '    using ::Fmx::Skia::SkFmxPixelFormat;'}
{$HPPEMIT END '    using ::Fmx::Skia::AddSkPathToPathData;'}
{$HPPEMIT END '    using ::Fmx::Skia::BitmapToSkImage;'}
{$HPPEMIT END '    using ::Fmx::Skia::DrawDesignBorder;'}
{$HPPEMIT END '    using ::Fmx::Skia::PathDataToSkPath;'}
{$HPPEMIT END '    using ::Fmx::Skia::SkiaDraw;'}
{$HPPEMIT END '    using ::Fmx::Skia::SkImageToBitmap;'}
{$HPPEMIT END '    using ::Fmx::Skia::SkPathToPathData;'}
{$HPPEMIT END '#endif'}

initialization
  RegisterFMXClasses([TSkAnimatedImage, TSkAnimatedPaintBox, TSkCustomControl, TSkLabel, TSkPaintBox,
    TSkStyledControl, TSkCustomStyleTextObject, TSkStyleTextObject, TSkSvgBrush, TSkSvg]);
  RegisterFMXClasses([TSkAnimatedImage.TAnimation, TSkAnimatedPaintBox.TAnimation, TSkCustomAnimation,
    TSkFontComponent, TSkTextSettings, TSkTextSettingsInfo, TSkTextSettings.TDecorations,
    TSkLabel.TCustomWordsItem, TSkLabel.TWordsCollection]);
  TSkAnimatedImage.RegisterCodec(TSkLottieAnimationCodec);
  TSkAnimatedImage.RegisterCodec(TSkDefaultAnimationCodec);
end.

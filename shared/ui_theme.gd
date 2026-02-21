class_name UITheme
## '피 묻은 동화책' 컨셉의 UI 테마. 공통 색상/스타일/빌더 함수를 제공한다.


## -- 색상 팔레트 --

# 배경
const BG_DARK := Color(0.06, 0.03, 0.09, 1.0)
const BG_OVERLAY := Color(0.04, 0.02, 0.07, 0.85)
const BG_PANEL := Color(0.1, 0.06, 0.14, 0.92)

# 포인트 색상
const GOLD := Color(0.92, 0.78, 0.35, 1.0)
const GOLD_DIM := Color(0.7, 0.58, 0.25, 1.0)
const BLOOD_RED := Color(0.78, 0.15, 0.12, 1.0)
const BLOOD_LIGHT := Color(0.95, 0.3, 0.25, 1.0)
const PURPLE := Color(0.55, 0.35, 0.7, 1.0)
const PURPLE_DIM := Color(0.4, 0.25, 0.5, 1.0)
const CREAM := Color(0.85, 0.8, 0.7, 1.0)

# 텍스트
const TEXT_BRIGHT := Color(0.9, 0.85, 0.75, 1.0)
const TEXT_NORMAL := Color(0.7, 0.65, 0.58, 1.0)
const TEXT_DIM := Color(0.45, 0.4, 0.35, 1.0)
const TEXT_DISABLED := Color(0.3, 0.28, 0.25, 1.0)

# 선택/하이라이트
const SELECT_ACTIVE := Color(0.95, 0.82, 0.4, 1.0)
const SELECT_INACTIVE := Color(0.5, 0.45, 0.38, 1.0)

# HUD 전용
const HP_FULL := Color(0.7, 0.2, 0.15, 1.0)       # 체력 높을 때 (진한 핏빛)
const HP_MID := Color(0.85, 0.45, 0.1, 1.0)        # 체력 중간 (경고 주황)
const HP_LOW := Color(0.95, 0.15, 0.1, 1.0)        # 체력 낮을 때 (밝은 빨강)
const HP_GREEN := Color(0.35, 0.7, 0.3, 1.0)       # 하위 호환용
const HP_RED := Color(0.8, 0.2, 0.15, 1.0)
const XP_BLUE := Color(0.3, 0.5, 0.85, 1.0)

# 테두리
const BORDER_GOLD := Color(0.7, 0.55, 0.2, 0.8)
const BORDER_DIM := Color(0.35, 0.25, 0.4, 0.6)

## -- 폰트 경로 --
const FONT_PATH := "res://assets/fonts/Galmuri11.ttf"
const FONT_SMALL_PATH := "res://assets/fonts/Galmuri7.ttf"

## -- 크기 상수 --
const TITLE_FONT_SIZE: int = 20
const HEADING_FONT_SIZE: int = 14
const BODY_FONT_SIZE: int = 11
const SMALL_FONT_SIZE: int = 8
const BORDER_WIDTH: int = 1
const PANEL_CORNER: int = 2


## -- StyleBox 빌더 --

static func make_panel_style(
	bg_color: Color = BG_PANEL,
	border_color: Color = BORDER_DIM,
	border_w: int = BORDER_WIDTH,
	corner: int = PANEL_CORNER,
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_w)
	style.set_corner_radius_all(corner)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	return style


static func make_card_style(
	highlight: bool = false,
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.05, 0.12, 0.95)
	style.border_color = BORDER_GOLD if highlight else BORDER_DIM
	style.set_border_width_all(2 if highlight else 1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	return style


static func make_hp_bar_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = HP_FULL
	style.set_corner_radius_all(1)
	return style


static func make_hp_bar_bg() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.05, 0.05, 0.9)
	style.border_color = Color(0.5, 0.15, 0.1, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(1)
	return style


static func make_xp_bar_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = XP_BLUE
	style.set_corner_radius_all(1)
	return style


static func make_xp_bar_bg() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.15, 0.9)
	style.border_color = Color(0.2, 0.25, 0.4, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(1)
	return style


static func make_boss_hp_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = BLOOD_RED
	style.set_corner_radius_all(1)
	return style


static func make_boss_hp_bg() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.05, 0.05, 0.9)
	style.border_color = Color(0.5, 0.15, 0.1, 0.7)
	style.set_border_width_all(1)
	style.set_corner_radius_all(1)
	return style


## -- 유틸 함수 --

static func apply_title_style(label: Label) -> void:
	label.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	label.add_theme_color_override("font_color", GOLD)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


static func apply_heading_style(label: Label, color: Color = GOLD) -> void:
	label.add_theme_font_size_override("font_size", HEADING_FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


static func apply_body_style(label: Label, color: Color = TEXT_NORMAL) -> void:
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


static func apply_hint_style(label: Label) -> void:
	label.add_theme_color_override("font_color", TEXT_DIM)
	label.add_theme_font_size_override("font_size", SMALL_FONT_SIZE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


static func make_separator(height: float = 1.0) -> ColorRect:
	var sep := ColorRect.new()
	sep.color = BORDER_DIM
	sep.custom_minimum_size = Vector2(0, height)
	return sep


static func make_vignette_border() -> ColorRect:
	var rect := ColorRect.new()
	rect.color = Color(0.0, 0.0, 0.0, 0.0)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

VsSeeker: ; 90b8d (24:4b8d)
	ld hl, Options1
	ld a, [hl]
	push af
	set NO_TEXT_SCROLL, [hl]
	ld a, [hInMenu]
	push af
	ld a, $1
	ld [hInMenu], a
	ld [wInVsSeeker], a
	ld a, [VramState]
	push af
	xor a
	ld [VramState], a
	call .InitTilemap
	call DelayFrame
.loop
	call UpdateTime
	call JoyTextDelay
	ld a, [wJumptableIndex]
	bit 7, a
	jr nz, .done
	call VsSeekerJumptable
	farcall PlaySpriteAnimations
	call DelayFrame
	jr .loop

.done
	ld de, SFX_READ_TEXT_2
	call PlaySFX
	call WaitSFX
	pop af
	ld [VramState], a
	pop af
	ld [hInMenu], a
	pop af
	ld [Options1], a
	call ClearBGPalettes
	xor a
	ld [hBGMapAddress], a
	ld [wInVsSeeker], a
	ld a, VBGMap0 / $100
	ld [hBGMapAddress + 1], a
	ld a, $90
	ld [hWY], a
	jp ExitPokegearRadio_HandleMusic

.InitTilemap: ; 90bea (24:4bea)
	call ClearBGPalettes
	call ClearTileMap
	call ClearSprites
	call DisableLCD
	xor a
	ld [hSCY], a
	ld [hSCX], a
	ld a, $7
	ld [hWX], a
	call Pokegear_LoadGFX
	farcall ClearSpriteAnims
	ld a, 8
	call SkipMusic
	ld a, %11100011
	ld [rLCDC], a
	call TownMap_InitCursorAndPlayerIconPositions
	xor a
	ld [wJumptableIndex], a
	ld [wcf65], a
	ld [wcf66], a
	ld [wPokegearPhoneScrollPosition], a
	ld [wPokegearPhoneCursorPosition], a
	ld [wPokegearPhoneSelectedPerson], a
	ld [wPokegearRadioChannelBank], a
	ld [wPokegearRadioChannelAddr], a
	ld [wPokegearRadioChannelAddr + 1], a
	call InitPokegearTilemap
	ld b, CGB_POKEGEAR_PALS
	call GetCGBLayout
	call SetPalettes
	ld a, %11100100
	jp DmgToCgbObjPal0

Pokegear_LoadGFX: ; 90c4e
	call ClearVBank1
	ld hl, TownMapGFX
	ld de, VTiles2
	ld a, BANK(TownMapGFX)
	call FarDecompress
	ld hl, PokegearGFX
	ld de, VTiles2 tile $40
	ld a, BANK(PokegearGFX)
	call Decompress
	ld hl, PokegearSpritesGFX
	ld de, VTiles0
	ld a, BANK(PokegearSpritesGFX)
	call Decompress
	ld a, [MapGroup]
	ld b, a
	ld a, [MapNumber]
	ld c, a
	call GetWorldMapLocation
	cp FAST_SHIP
	jr z, .ssaqua
	cp SINJOH_RUINS
	jr z, .sinjoh
	cp MYSTRI_STAGE
	jr z, .sinjoh
	farcall GetPlayerIcon
	push de
	ld h, d
	ld l, e
	ld a, b
	; standing sprite
	push af
	ld de, VTiles0 tile $10
	ld bc, 4 tiles
	call FarCopyBytes
	pop af
	pop hl
	; walking sprite
	ld de, 12 tiles
	add hl, de
	ld de, VTiles0 tile $14
	ld bc, 4 tiles
	jp FarCopyBytes

.ssaqua
	ld hl, FastShipGFX
.loadaltsprite
	ld de, VTiles0 tile $10
	ld bc, 8 tiles
	jp CopyBytes

.sinjoh
	ld hl, SinjohRuinsArrowGFX
	jr .loadaltsprite

; 90cb2

FastShipGFX: ; 90cb2
INCBIN "gfx/town_map/fast_ship.2bpp"
; 90d32

SinjohRuinsArrowGFX:
INCBIN "gfx/pokegear/arrow.2bpp"

TownMap_InitCursorAndPlayerIconPositions: ; 90d70 (24:4d70)
	call GetCurrentLandmark
	ld [wPokegearMapPlayerIconLandmark], a
	ld [wPokegearMapCursorLandmark], a
	ret

InitPokegearTilemap: ; 90da8 (24:4da8)
	xor a
	ld [hBGMapMode], a
	hlcoord 0, 0
	ld bc, TileMapEnd - TileMap
	ld a, $40
	call ByteFill
	ld de, PhoneTilemapRLE
	call Pokegear_LoadTilemapRLE
	hlcoord 0, 12
	lb bc, 4, 18
	call TextBox
	hlcoord 17, 1
	ld a, $41
	ld [hli], a
	inc a
	ld [hl], a
	hlcoord 17, 2
	inc a
	ld [hli], a
	call GetMapHeaderPhoneServiceNybble
	and a
	jr nz, .no_service
	hlcoord 18, 2
	ld [hl], $44
.no_service
	call PokegearPhone_UpdateDisplayList
	call TownMapPals
	ld a, [wcf65]
	and a
	jr nz, .transition
	xor a
	ld [hBGMapAddress], a
	ld a, VBGMap0 / $100
	ld [hBGMapAddress + 1], a
	call .UpdateBGMap
	ld a, $90
	jr .finish

.transition
	xor a
	ld [hBGMapAddress], a
	ld a, VBGMap1 / $100
	ld [hBGMapAddress + 1], a
	call .UpdateBGMap
	xor a
.finish
	ld [hWY], a
	ld a, [wcf65]
	and 1
	xor 1
	ld [wcf65], a
	ret

.UpdateBGMap: ; 90e00 (24:4e00)
	ld a, $2
	ld [hBGMapMode], a
	ld c, 3
	call DelayFrames
	jp WaitBGMap

; 90e12 (24:4e12)

VsSeekerJumptable: ; 90f04 (24:4f04)
	ld a, [wJumptableIndex]
	ld e, a
	ld d, 0
	ld hl, .Jumptable
	add hl, de
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp hl

.Jumptable: ; 90f13 (24:4f13)
	dw PokegearPhone_Init
	dw PokegearPhone_Joypad
	dw PokegearPhone_MakePhoneCall
	dw PokegearPhone_FinishPhoneCall

SkipHiddenOrangeIslandsUp:
	call CheckSkipNavelRock
	jr nz, .not_after_navel_rock
	inc [hl]
.not_after_navel_rock
	call CheckSkipFarawayIsland
	jr nz, .not_after_faraway_island
	inc [hl]
.not_after_faraway_island
	ld a, [hl]
	cp FARAWAY_ISLAND + 1
	ret nz
	ld [hl], SHAMOUTI_ISLAND
	ret

SkipHiddenOrangeIslandsDown:
	call CheckSkipFarawayIsland
	jr nz, .not_before_faraway_island
	dec [hl]
.not_before_faraway_island
	call CheckSkipNavelRock
	ret nz
	dec [hl]
	ret

CheckSkipNavelRock:
	ld a, [hl]
	cp NAVEL_ROCK
	ret nz
	push hl
	eventflagcheck EVENT_VISITED_NAVEL_ROCK
	pop hl
	ret

CheckSkipFarawayIsland:
	ld a, [hl]
	cp FARAWAY_ISLAND
	ret nz
	push hl
	eventflagcheck EVENT_VISITED_FARAWAY_ISLAND
	pop hl
	ret

PokegearMap_InitPlayerIcon: ; 9106a
	push af
	depixel 0, 0
	ld b, SPRITE_ANIM_INDEX_RED_WALK
	ld a, [PlayerGender]
	bit 0, a
	jr z, .got_gender
	ld b, SPRITE_ANIM_INDEX_BLUE_WALK
.got_gender
	ld a, b
	call _InitSpriteAnimStruct
	ld hl, SPRITEANIMSTRUCT_TILE_ID
	add hl, bc
	ld [hl], $10
	pop af
	ld e, a
	push bc
	farcall GetLandmarkCoords
	pop bc
	ld hl, SPRITEANIMSTRUCT_XCOORD
	add hl, bc
	ld [hl], e
	ld hl, SPRITEANIMSTRUCT_YCOORD
	add hl, bc
	ld [hl], d
	ret

; 91098

PokegearMap_InitCursor: ; 91098
	push af
	depixel 0, 0
	ld a, SPRITE_ANIM_INDEX_POKEGEAR_MODE_ARROW
	call _InitSpriteAnimStruct
	ld hl, SPRITEANIMSTRUCT_TILE_ID
	add hl, bc
	ld [hl], $4
	ld hl, SPRITEANIMSTRUCT_ANIM_SEQ_ID
	add hl, bc
	ld [hl], SPRITE_ANIM_SEQ_NULL
	pop af
	push bc
	call PokegearMap_UpdateCursorPosition
	pop bc
	ret

; 910b4

PokegearMap_UpdateLandmarkName: ; 910b4
	push af
	hlcoord 8, 0
	lb bc, 2, 12
	call ClearBox
	pop af
	ld e, a
	push de
	farcall GetLandmarkName
	pop de
	call TownMap_ConvertLineBreakCharacters
	hlcoord 8, 0
	ld [hl], "<UPDN>"
	ret

; 910d4

PokegearMap_UpdateCursorPosition: ; 910d4
	push bc
	ld e, a
	farcall GetLandmarkCoords
	pop bc
	ld hl, SPRITEANIMSTRUCT_XCOORD
	add hl, bc
	ld [hl], e
	ld hl, SPRITEANIMSTRUCT_YCOORD
	add hl, bc
	ld [hl], d
	ret
; 910e8

TownMap_ConvertLineBreakCharacters: ; 1de2c5
	ld hl, StringBuffer1
.loop
	ld a, [hl]
	cp "@"
	jr z, .end
	cp "<NEXT>"
	jr z, .line_break
	cp "¯"
	jr z, .line_break
	inc hl
	jr .loop

.line_break
	ld [hl], "<LNBRK>"

.end
	ld de, StringBuffer1
	hlcoord 9, 0
	jp PlaceString

TownMap_GetJohtoLandmarkLimits:
	lb de, SILVER_CAVE, NEW_BARK_TOWN
	ret

TownMap_GetKantoLandmarkLimits: ; 910e8
	lb de, ROUTE_28, ROUTE_27
	ld a, [StatusFlags]
	bit 6, a
	ret z
	ld e, PALLET_TOWN
	ret

TownMap_GetOrangeLandmarkLimits:
	lb de, FARAWAY_ISLAND, SHAMOUTI_ISLAND
	ret

; 910f9

PokegearPhone_Init: ; 91156 (24:5156)
	ld hl, wJumptableIndex
	inc [hl]
	xor a
	ld [wPokegearPhoneScrollPosition], a
	ld [wPokegearPhoneCursorPosition], a
	ld [wPokegearPhoneSelectedPerson], a

	ld b, CGB_POKEGEAR_PALS
	call GetCGBLayout
	call SetPalettes

	call InitPokegearTilemap
	call ExitPokegearRadio_HandleMusic
	ld hl, PokegearText_WhomToCall
	jp PrintText

PokegearPhone_Joypad: ; 91171 (24:5171)
	ld hl, hJoyPressed
	ld a, [hl]
	and B_BUTTON
	jr nz, .b
	ld a, [hl]
	and A_BUTTON
	jr nz, .a
	jp PokegearPhone_GetDPad

.b
	ld hl, wJumptableIndex
	set 7, [hl]
	ret

.a
	ld hl, wPhoneList
	ld a, [wPokegearPhoneScrollPosition]
	ld e, a
	ld d, 0
	add hl, de
	ld a, [wPokegearPhoneCursorPosition]
	ld e, a
	ld d, 0
	add hl, de
	ld a, [hl]
	and a
	ret z
	ld [wPokegearPhoneSelectedPerson], a
	hlcoord 1, 4
	ld a, [wPokegearPhoneCursorPosition]
	ld bc, 20 * 2
	call AddNTimes
	ld [hl], "▷"
	call PokegearPhoneContactSubmenu
	jr c, .quit_submenu
	ld hl, wJumptableIndex
	inc [hl]
	ret

.quit_submenu
	ld a, $1
	ld [wJumptableIndex], a
	ret

PokegearPhone_MakePhoneCall: ; 911eb (24:51eb)
	call GetMapHeaderPhoneServiceNybble
	and a
	jr nz, .no_service
	ld hl, Options1
	res NO_TEXT_SCROLL, [hl]
	xor a
	ld [hInMenu], a
	ld de, SFX_CALL
	call PlaySFX
	ld hl, .dotdotdot
	call PrintText
	call WaitSFX
	ld de, SFX_CALL
	call PlaySFX
	ld hl, .dotdotdot
	call PrintText
	call WaitSFX
	ld a, [wPokegearPhoneSelectedPerson]
	ld b, a
	call Function90199
	ld c, 10
	call DelayFrames
	ld hl, Options1
	set NO_TEXT_SCROLL, [hl]
	ld a, $1
	ld [hInMenu], a
	call PokegearPhone_UpdateCursor
	ld hl, wJumptableIndex
	inc [hl]
	ret

.no_service
	farcall Phone_NoSignal
	ld hl, .OutOfServiceArea
	call PrintText
	ld a, $1
	ld [wJumptableIndex], a
	ld hl, PokegearText_WhomToCall
	jp PrintText

; 9124c (24:524c)

.dotdotdot ; 0x9124c
	;
	text_jump UnknownText_0x1c5824
	db "@"

; 0x91251

.OutOfServiceArea: ; 0x91251
	; You're out of the service area.
	text_jump UnknownText_0x1c5827
	db "@"

; 0x91256

PokegearPhone_FinishPhoneCall: ; 91256 (24:5256)
	ld a, [hJoyPressed]
	and A_BUTTON | B_BUTTON
	ret z
	farcall HangUp
	ld a, $1
	ld [wJumptableIndex], a
	ld hl, PokegearText_WhomToCall
	jp PrintText

PokegearPhone_GetDPad: ; 9126d (24:526d)
	ld hl, hJoyLast
	ld a, [hl]
	and D_UP
	jr nz, .up
	ld a, [hl]
	and D_DOWN
	jr nz, .down
	ret

.up
	ld hl, wPokegearPhoneCursorPosition
	ld a, [hl]
	and a
	jr z, .scroll_page_up
	dec [hl]
	jr .done_joypad_same_page

.scroll_page_up
	ld hl, wPokegearPhoneScrollPosition
	ld a, [hl]
	and a
	ret z
	dec [hl]
	jr .done_joypad_update_page

.down
	ld hl, wPokegearPhoneCursorPosition
	ld a, [hl]
	cp $3
	jr nc, .scroll_page_down
	inc [hl]
	jr .done_joypad_same_page

.scroll_page_down
	ld hl, wPokegearPhoneScrollPosition
	ld a, [hl]
	cp CONTACT_LIST_SIZE - 4
	ret nc
	inc [hl]
	jr .done_joypad_update_page

.done_joypad_same_page
	xor a
	ld [hBGMapMode], a
	call PokegearPhone_UpdateCursor
	jp WaitBGMap

.done_joypad_update_page
	xor a
	ld [hBGMapMode], a
	call PokegearPhone_UpdateDisplayList
	jp WaitBGMap

PokegearPhone_UpdateCursor: ; 912b7 (24:52b7)
	ld a, " "
	hlcoord 1, 4
	ld [hl], a
	hlcoord 1, 6
	ld [hl], a
	hlcoord 1, 8
	ld [hl], a
	hlcoord 1, 10
	ld [hl], a
	hlcoord 1, 4
	ld a, [wPokegearPhoneCursorPosition]
	ld bc, 2 * SCREEN_WIDTH
	call AddNTimes
	ld [hl], "▶"
	ret

PokegearPhone_UpdateDisplayList: ; 912d8 (24:52d8)
	hlcoord 1, 3
	ld b, 9
	ld a, " "
.row
	ld c, 18
.col
	ld [hli], a
	dec c
	jr nz, .col
	inc hl
	inc hl
	dec b
	jr nz, .row
	ld a, [wPokegearPhoneScrollPosition]
	ld e, a
	ld d, $0
	ld hl, wPhoneList
	add hl, de
	xor a
	ld [wPokegearPhoneLoadNameBuffer], a
.loop
	ld a, [hli]
	push hl
	push af
	hlcoord 2, 4
	ld a, [wPokegearPhoneLoadNameBuffer]
	ld bc, 2 * SCREEN_WIDTH
	call AddNTimes
	ld d, h
	ld e, l
	pop af
	ld b, a
	call Function90380
	pop hl
	ld a, [wPokegearPhoneLoadNameBuffer]
	inc a
	ld [wPokegearPhoneLoadNameBuffer], a
	cp $4 ; 4 entries fit on the screen
	jr c, .loop
	jp PokegearPhone_UpdateCursor

; 9131e (24:531e)

PokegearPhone_DeletePhoneNumber: ; 9131e
	ld hl, wPhoneList
	ld a, [wPokegearPhoneScrollPosition]
	ld e, a
	ld d, 0
	add hl, de
	ld a, [wPokegearPhoneCursorPosition]
	ld e, a
	ld d, 0
	add hl, de
	ld [hl], 0
	ld hl, wPhoneList
	ld c, CONTACT_LIST_SIZE
.loop
	ld a, [hli]
	and a
	jr nz, .skip
	ld a, [hld]
	ld [hli], a
	ld [hl], 0
.skip
	dec c
	jr nz, .loop
	ret

; 91342

PokegearPhoneContactSubmenu: ; 91342 (24:5342)
	ld hl, wPhoneList
	ld a, [wPokegearPhoneScrollPosition]
	ld e, a
	ld d, 0
	add hl, de
	ld a, [wPokegearPhoneCursorPosition]
	ld e, a
	ld d, 0
	add hl, de
	ld c, [hl]
	farcall CheckCanDeletePhoneNumber
	ld a, c
	and a
	jr z, .cant_delete
	ld hl, .CallDeleteCancelJumptable
	ld de, .CallDeleteCancelStrings
	jr .got_menu_data

.cant_delete
	ld hl, .CallCancelJumptable
	ld de, .CallCancelStrings
.got_menu_data
	xor a
	ld [hBGMapMode], a
	push hl
	push de
	ld a, [de]
	ld l, a
	inc de
	ld a, [de]
	ld h, a
	inc de
	push hl
	ld bc, hBGMapAddress + 1
	add hl, bc
	ld a, [de]
	inc de
	sla a
	ld b, a
	ld c, 8
	push de
	call TextBox
	pop de
	pop hl
	inc hl
	call PlaceString
	pop de
	xor a
	ld [wPokegearPhoneSubmenuCursor], a
	call .UpdateCursor
	call WaitBGMap
.loop
	push de
	call JoyTextDelay
	pop de
	ld hl, hJoyPressed
	ld a, [hl]
	and D_UP
	jr nz, .d_up
	ld a, [hl]
	and D_DOWN
	jr nz, .d_down
	ld a, [hl]
	and A_BUTTON | B_BUTTON
	jr nz, .a_b
	call DelayFrame
	jr .loop

.d_up
	ld hl, wPokegearPhoneSubmenuCursor
	ld a, [hl]
	and a
	jr z, .loop
	dec [hl]
	call .UpdateCursor
	jr .loop

.d_down
	ld hl, 2
	add hl, de
	ld a, [wPokegearPhoneSubmenuCursor]
	inc a
	cp [hl]
	jr nc, .loop
	ld [wPokegearPhoneSubmenuCursor], a
	call .UpdateCursor
	jr .loop

.a_b
	xor a
	ld [hBGMapMode], a
	call PokegearPhone_UpdateDisplayList
	ld a, $1
	ld [hBGMapMode], a
	pop hl
	ld a, [hJoyPressed]
	and B_BUTTON
	jr nz, .Cancel
	ld a, [wPokegearPhoneSubmenuCursor]
	ld e, a
	ld d, 0
	add hl, de
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp hl

.Cancel: ; 913f1
	ld hl, PokegearText_WhomToCall
	call PrintText
	scf
	ret

; 913f9 (24:53f9)

.Delete: ; 913f9
	ld hl, PokegearText_DeleteStoredNumber
	call MenuTextBox
	call YesNoBox
	call ExitMenu
	jr c, .CancelDelete
	call PokegearPhone_DeletePhoneNumber
	xor a
	ld [hBGMapMode], a
	call PokegearPhone_UpdateDisplayList
	ld hl, PokegearText_WhomToCall
	call PrintText
	call WaitBGMap
.CancelDelete:
	scf
	ret

; 9141b

.Call: ; 9141b
	and a
	ret

; 9141d

.UpdateCursor: ; 9141d (24:541d)
	push de
	ld a, [de]
	inc de
	ld l, a
	ld a, [de]
	inc de
	ld h, a
	ld a, [de]
	ld c, a
	push hl
	ld a, " "
	ld de, SCREEN_WIDTH * 2
.clear_column
	ld [hl], a
	add hl, de
	dec c
	jr nz, .clear_column
	pop hl
	ld a, [wPokegearPhoneSubmenuCursor]
	ld bc, SCREEN_WIDTH  * 2
	call AddNTimes
	ld [hl], "▶"
	pop de
	ret

; 9143f (24:543f)

.CallDeleteCancelStrings: ; 9143f
	dwcoord 10, 6
	db 3
	db   "Call"
	next "Delete"
	next "Cancel"
	db   "@"
; 91455

.CallDeleteCancelJumptable: ; 91455
	dw .Call
	dw .Delete
	dw .Cancel

; 9145b

.CallCancelStrings: ; 9145b
	dwcoord 10, 8
	db 2
	db   "Call"
	next "Cancel"
	db   "@"
; 9146a

.CallCancelJumptable: ; 9146a
	dw .Call
	dw .Cancel

; 9146e

ExitPokegearRadio_HandleMusic: ; 91492
	ld a, [wPokegearRadioMusicPlaying]
	cp $fe
	jr z, .restart_map_music
	cp $ff
	call z, EnterMapMusic
	xor a
	ld [wPokegearRadioMusicPlaying], a
	ret

.restart_map_music
	call RestartMapMusic
	xor a
	ld [wPokegearRadioMusicPlaying], a
	ret

; 914ab

DeleteSpriteAnimStruct2ToEnd: ; 914ab (24:54ab)
	ld hl, SpriteAnim2
	ld bc, wSpriteAnimationStructsEnd - SpriteAnim2
	xor a
	call ByteFill
	ld a, 2
	ld [wSpriteAnimCount], a
	ret

Pokegear_LoadTilemapRLE: ; 914bb (24:54bb)
	; Format: repeat count, tile ID
	; Terminated with $FF
	hlcoord 0, 0
.loop
	ld a, [de]
	cp $ff
	ret z
	ld b, a
	inc de
	ld a, [de]
	ld c, a
	inc de
	ld a, b
.load
	ld [hli], a
	dec c
	jr nz, .load
	jr .loop

; 914ce (24:54ce)

PokegearText_WhomToCall: ; 0x914ce
	; Whom do you want to call?
	text_jump UnknownText_0x1c5847
	db "@"

; 0x914d3

PokegearText_PressAnyButtonToExit: ; 0x914d3
	; Press any button to exit.
	text_jump UnknownText_0x1c5862
	db "@"

; 0x914d8

PokegearText_DeleteStoredNumber: ; 0x914d8
	; Delete this stored phone number?
	text_jump UnknownText_0x1c587d
	db "@"

; 0x914dd

PokegearSpritesGFX: ; 914dd
INCBIN "gfx/pokegear/pokegear_sprites.2bpp.lz"
; 9150d

PhoneTilemapRLE: ; 9158a
INCBIN "gfx/pokegear/phone.tilemap.rle"
; 9163e

RadioMusicRestartDE: ; 91854 (24:5854)
	push de
	ld a, e
	ld [wPokegearRadioMusicPlaying], a
	ld de, MUSIC_NONE
	call PlayMusic
	pop de
	ld a, e
	ld [wMapMusic], a
	jp PlayMusic

RadioMusicRestartPokemonChannel: ; 91868 (24:5868)
	push de
	ld a, $fe
	ld [wPokegearRadioMusicPlaying], a
	ld de, MUSIC_NONE
	call PlayMusic
	pop de
	ld de, MUSIC_OAKS_LAB
	jp PlayMusic

NoRadioMusic: ; 9189d (24:589d)
	ld de, MUSIC_NONE
	call PlayMusic
	ld a, $ff
	ld [wPokegearRadioMusicPlaying], a
	ret

NoRadioName: ; 918a9 (24:58a9)
	xor a
	ld [hBGMapMode], a
	hlcoord 1, 8
	lb bc, 3, 18
	call ClearBox
	hlcoord 0, 12
	ld bc, $412
	jp TextBox

; 918bf

OaksPkmnTalkName:     db "Oak's <PK><MN> Talk@"
PokedexShowName:      db "#dex Show@"
PokemonMusicName:     db "#mon Music@"
LuckyChannelName:     db "Lucky Channel@"
UnknownStationName:   db "?????@"

PlacesAndPeopleName:  db "Places & People@"
LetsAllSingName:      db "Let's All Sing!@"
PokeFluteStationName: db "# Flute@"
; 9191c

_TownMap: ; 9191c
	ld hl, Options1
	ld a, [hl]
	push af
	set NO_TEXT_SCROLL, [hl]

	ld a, [hInMenu]
	push af
	ld a, $1
	ld [hInMenu], a

	ld a, [VramState]
	push af
	xor a
	ld [VramState], a

	call ClearBGPalettes
	call ClearTileMap
	call ClearSprites
	call DisableLCD
	call Pokegear_LoadGFX
	farcall ClearSpriteAnims
	ld a, 8
	call SkipMusic
	ld a, %11100011
	ld [rLCDC], a
	call TownMap_InitCursorAndPlayerIconPositions
	ld [wTownMapPlayerIconLandmark], a
	ld [wTownMapCursorLandmark], a
	xor a
	ld [hBGMapMode], a
	call .InitTilemap
	call WaitBGMap2
	ld a, [wTownMapPlayerIconLandmark]
	call PokegearMap_InitPlayerIcon
	ld a, [wTownMapCursorLandmark]
	call PokegearMap_InitCursor
	ld a, c
	ld [wTownMapCursorObjectPointer], a
	ld a, b
	ld [wTownMapCursorObjectPointer + 1], a
	ld b, CGB_POKEGEAR_PALS
	call GetCGBLayout
	call SetPalettes
	ld a, %11100100
	call DmgToCgbObjPal0
	call DelayFrame

	ld a, [wTownMapPlayerIconLandmark]
	cp SHAMOUTI_LANDMARK
	jr nc, .orange
	cp KANTO_LANDMARK
	jr nc, .kanto
	call TownMap_GetJohtoLandmarkLimits
	jr .resume
.kanto
	call TownMap_GetKantoLandmarkLimits
	jr .resume
.orange
	call TownMap_GetOrangeLandmarkLimits

.resume
	call .loop
	pop af
	ld [VramState], a
	pop af
	ld [hInMenu], a
	pop af
	ld [Options1], a
	jp ClearBGPalettes

.loop
	call JoyTextDelay
	ld hl, hJoyPressed
	ld a, [hl]
	and B_BUTTON
	ret nz

	ld hl, hJoyLast
	ld a, [hl]
	and D_UP
	jr nz, .pressed_up

	ld a, [hl]
	and D_DOWN
	jr nz, .pressed_down
.loop2
	push de
	farcall PlaySpriteAnimations
	pop de
	call DelayFrame
	jr .loop

.pressed_up
	ld hl, wTownMapCursorLandmark
	ld a, [hl]
	cp d
	jr c, .okay
	ld a, e
	dec a
	ld [hl], a

.okay
	inc [hl]
	push de
	call SkipHiddenOrangeIslandsUp
	jr .next

.pressed_down
	ld hl, wTownMapCursorLandmark
	ld a, [hl]
	cp e
	jr nz, .okay2
	ld a, d
	inc a
	ld [hl], a

.okay2
	dec [hl]
	push de
	call SkipHiddenOrangeIslandsDown

.next
	ld a, [wTownMapCursorLandmark]
	call PokegearMap_UpdateLandmarkName
	ld a, [wTownMapCursorObjectPointer]
	ld c, a
	ld a, [wTownMapCursorObjectPointer + 1]
	ld b, a
	ld a, [wTownMapCursorLandmark]
	call PokegearMap_UpdateCursorPosition
	pop de
	jr .loop2
; 91a04

.InitTilemap: ; 91a04
	farcall PokegearMap
	ld a, $7
	ld bc, 6
	hlcoord 1, 0
	call ByteFill
	hlcoord 0, 0
	ld [hl], $6
	hlcoord 7, 0
	ld [hl], $17
	hlcoord 7, 1
	ld [hl], $16
	hlcoord 7, 2
	ld [hl], $26
	ld a, $7
	ld bc, NAME_LENGTH
	hlcoord 8, 2
	call ByteFill
	hlcoord 19, 2
	ld [hl], $17
	ld a, [wTownMapCursorLandmark]
	call PokegearMap_UpdateLandmarkName
	call TownMapPals

	ld a, [wTownMapPlayerIconLandmark]
	cp SHAMOUTI_LANDMARK
	jp nc, TownMapOrangeFlips
	cp KANTO_LANDMARK
	jp nc, TownMapKantoFlips
	jp TownMapJohtoFlips
; 91a53

PokegearMap: ; 91ae1
	call LoadTownMapGFX
	ld a, [wPokegearMapPlayerIconLandmark]
	cp SHAMOUTI_LANDMARK
	jp nc, FillOrangeMap
	cp KANTO_LANDMARK
	jp nc, FillKantoMap
	jp FillJohtoMap
; 91af3

_FlyMap: ; 91af3
	call ClearBGPalettes
	call ClearTileMap
	call ClearSprites
	ld hl, hInMenu
	ld a, [hl]
	push af
	ld [hl], $1
	xor a
	ld [hBGMapMode], a
	farcall ClearSpriteAnims
	call LoadTownMapGFX
	call FlyMap
	ld b, CGB_POKEGEAR_PALS
	call GetCGBLayout
	call SetPalettes
.loop
	call JoyTextDelay
	ld hl, hJoyPressed
	ld a, [hl]
	and B_BUTTON
	jr nz, .pressedB
	ld a, [hl]
	and A_BUTTON
	jr nz, .pressedA
	call FlyMapScroll
	call GetMapCursorCoordinates
	farcall PlaySpriteAnimations
	call DelayFrame
	jr .loop

.pressedB
	ld a, -1
	jr .exit

.pressedA
	ld a, [wTownMapPlayerIconLandmark]
	ld l, a
	ld h, 0
	add hl, hl
	ld de, Flypoints + 1
	add hl, de
	ld a, [hl]
.exit
	ld [wTownMapPlayerIconLandmark], a
	pop af
	ld [hInMenu], a
	call ClearBGPalettes
	ld a, $90
	ld [hWY], a
	xor a
	ld [hBGMapAddress], a
	ld a, VBGMap0 / $100
	ld [hBGMapAddress + 1], a
	ld a, [wTownMapPlayerIconLandmark]
	ld e, a
	ret

; 91b73

FlyMapScroll: ; 91b73
	ld a, [StartFlypoint]
	ld e, a
	ld a, [EndFlypoint]
	ld d, a
	ld hl, hJoyLast
	ld a, [hl]
	and D_UP
	jr nz, .ScrollNext
	ld a, [hl]
	and D_DOWN
	jr nz, .ScrollPrev
	ret

.ScrollNext:
	ld hl, wTownMapPlayerIconLandmark
	ld a, [hl]
	cp d
	jr nz, .NotAtEndYet
	ld a, e
	dec a
	ld [hl], a
.NotAtEndYet:
	inc [hl]
	call CheckIfVisitedFlypoint
	jr z, .ScrollNext
	jr .Finally

.ScrollPrev:
	ld hl, wTownMapPlayerIconLandmark
	ld a, [hl]
	cp e
	jr nz, .NotAtStartYet
	ld a, d
	inc a
	ld [hl], a
.NotAtStartYet:
	dec [hl]
	call CheckIfVisitedFlypoint
	jr z, .ScrollPrev
.Finally:
	call TownMapBubble
	call WaitBGMap
	xor a
	ld [hBGMapMode], a
	ret

; 91bb5

TownMapBubble: ; 91bb5
; Draw the bubble containing the location text in the town map HUD

; Top-left corner
	hlcoord 1, 0
	ld a, $37
	ld [hli], a
; Top row
	ld bc, 16
	ld a, " "
	call ByteFill
; Top-right corner
	ld a, $38
	ld [hl], a
	hlcoord 1, 1

; Middle row
	ld bc, 18
	ld a, " "
	call ByteFill

; Bottom-left corner
	hlcoord 1, 2
	ld a, $39
	ld [hli], a
; Bottom row
	ld bc, 16
	ld a, " "
	call ByteFill
; Bottom-right corner
	ld a, $3a
	ld [hl], a

; Print "Where?"
	hlcoord 2, 0
	ld de, .Where
	call PlaceString
; Print the name of the default flypoint
	call .Name
; Up/down arrows
	hlcoord 18, 1
	ld [hl], "<UPDN>"
	ret

.Where:
	db "Where?@"

.Name:
; We need the map location of the default flypoint
	ld a, [wTownMapPlayerIconLandmark]
	ld l, a
	ld h, 0
	add hl, hl ; two bytes per flypoint
	ld de, Flypoints
	add hl, de
	ld e, [hl]
	farcall GetLandmarkName
	hlcoord 2, 1
	ld de, StringBuffer1
	jp PlaceString

; 91c17

GetMapCursorCoordinates: ; 91c17
	ld a, [wTownMapPlayerIconLandmark]
	ld l, a
	ld h, $0
	add hl, hl
	ld de, Flypoints
	add hl, de
	ld e, [hl]
	farcall GetLandmarkCoords
	ld a, [wTownMapCursorCoordinates]
	ld c, a
	ld a, [wTownMapCursorCoordinates + 1]
	ld b, a
	ld hl, $4
	add hl, bc
	ld [hl], e
	ld hl, $5
	add hl, bc
	ld [hl], d
	ret

; 91c3c

CheckIfVisitedFlypoint: ; 91c3c
; Check if the flypoint loaded in [hl] has been visited yet.
	push bc
	push de
	push hl
	ld l, [hl]
	ld h, 0
	add hl, hl
	ld de, Flypoints + 1
	add hl, de
	ld c, [hl]
	call HasVisitedSpawn
	pop hl
	pop de
	pop bc
	and a
	ret

; 91c50

HasVisitedSpawn: ; 91c50
; Check if spawn point c has been visited.
	ld hl, VisitedSpawns
	ld b, CHECK_FLAG
	ld d, 0
	predef FlagPredef
	ld a, c
	ret

; 91c5e

INCLUDE "data/maps/flypoints.asm"

FlyMap: ; 91c90
	call GetCurrentLandmark
; The first 46 locations are part of Johto. The rest are in Kanto
	cp KANTO_LANDMARK
	jr nc, .KantoFlyMap
;.JohtoFlyMap:
; Note that .NoKanto should be modified in tandem with this branch
	push af
; Start from New Bark Town
	ld a, FLY_NEW_BARK
	ld [wTownMapPlayerIconLandmark], a
; Flypoints begin at New Bark Town...
	ld [StartFlypoint], a
; ..and end at Silver Cave
	ld a, FLY_MT_SILVER
	ld [EndFlypoint], a
; Fill out the map
	call FillJohtoMap
	call TownMapBubble
	call TownMapPals
	call TownMapJohtoFlips
	call .MapHud
	pop af
	jp TownMapPlayerIcon

.KantoFlyMap:
; The event that there are no flypoints enabled in a map is not

; accounted for. As a result, if you attempt to select a flypoint
; when there are none enabled, the game will crash. Additionally,

; the flypoint selection has a default starting point that
; can be flown to even if none are enabled

; To prevent both of these things from happening when the player
; enters Kanto, fly access is restricted until Indigo Plateau is

; visited and its flypoint enabled
	push af
	ld c, SPAWN_INDIGO
	call HasVisitedSpawn
	and a
	jr z, .NoKanto
; Kanto's map is only loaded if we've visited Indigo Plateau

; Flypoints begin at Pallet Town...
	ld a, FLY_PALLET
	ld [StartFlypoint], a
; ...and end at Indigo Plateau
	ld a, FLY_INDIGO
	ld [EndFlypoint], a
; Because Indigo Plateau is the first flypoint the player

; visits, it's made the default flypoint
	ld [wTownMapPlayerIconLandmark], a
; Fill out the map
	call FillKantoMap
	call TownMapBubble
	call TownMapPals
	call TownMapKantoFlips
	call .MapHud
	pop af
	jp TownMapPlayerIcon

.NoKanto:
; If Indigo Plateau hasn't been visited, we use Johto's map instead

; Start from New Bark Town
	ld a, FLY_NEW_BARK
	ld [wTownMapPlayerIconLandmark], a
; Flypoints begin at New Bark Town...
	ld [StartFlypoint], a
; ..and end at Silver Cave
	ld a, FLY_MT_SILVER
	ld [EndFlypoint], a
	call FillJohtoMap
	pop af
	call TownMapBubble
	call TownMapPals
	call TownMapJohtoFlips
.MapHud:
	hlbgcoord 0, 0 ; BG Map 0
	call TownMapBGUpdate
	call TownMapMon
	ld a, c
	ld [wTownMapCursorCoordinates], a
	ld a, b
	ld [wTownMapCursorCoordinates + 1], a
	ret

; 91d11

_Area: ; 91d11
; e: Current landmark
	ld a, [wTownMapPlayerIconLandmark]
	push af
	ld a, [wTownMapCursorLandmark]
	push af
	ld a, e
	ld [wTownMapPlayerIconLandmark], a
	call ClearSprites
	xor a
	ld [hBGMapMode], a
	ld a, $1
	ld [hInMenu], a
	ld de, PokedexNestIconGFX
	ld hl, VTiles0 tile $7f
	lb bc, BANK(PokedexNestIconGFX), 1
	call Request2bpp
	call .GetPlayerOrFastShipIcon
	ld hl, VTiles0 tile $78
	ld c, 4
	call Request2bpp
	call LoadTownMapGFX

	ld a, [wTownMapPlayerIconLandmark]
	cp SHAMOUTI_LANDMARK
	jr nc, .shamouti
	cp KANTO_LANDMARK
	jr nc, .kanto
.johto
	ld a, JOHTO_REGION
	jr .set_region
.shamouti
	ld a, ORANGE_REGION
	jr .set_region
.kanto
	ld a, KANTO_REGION
.set_region
	ld [wTownMapCursorLandmark], a
	call .UpdateGFX
	call .GetAndPlaceNest
.loop
	call JoyTextDelay
	ld hl, hJoyPressed
	ld a, [hl]
	and A_BUTTON | B_BUTTON
	jr nz, .a_b
	ld a, [hJoypadDown]
	and SELECT
	jr nz, .select
	call .LeftRightInput
	call .BlinkNestIcons
	jr .next

.select
	call .HideNestsShowPlayer
.next
	call DelayFrame
	jr .loop

.a_b
	call ClearSprites
	pop af
	ld [wTownMapCursorLandmark], a
	pop af
	ld [wTownMapPlayerIconLandmark], a
	ret

; 91d9b

.LeftRightInput: ; 91d9b
	ld a, [hl]
	and D_LEFT
	jr nz, .left
	ld a, [hl]
	and D_RIGHT
	jr nz, .right
	ret

.left
	ld a, [wTownMapCursorLandmark]
	and a ; cp JOHTO_REGION ; min
	ret z

	dec a
	ld [wTownMapCursorLandmark], a
	jr .update

.right
	ld a, [wTownMapCursorLandmark]
	cp ORANGE_REGION ; max
	ret z
	cp KANTO_REGION
	jr z, .check_seen_orange_island
	ld a, [StatusFlags]
	bit 6, a ; ENGINE_CREDITS_SKIP
	ret z
	jr .go_right
.check_seen_orange_island
	ld a, [StatusFlags2]
	bit 3, a ; ENGINE_SEEN_SHAMOUTI_ISLAND
	ret z
.go_right

	ld a, [wTownMapCursorLandmark]
	inc a
	ld [wTownMapCursorLandmark], a

.update
	call .UpdateGFX
	jp .GetAndPlaceNest

.UpdateGFX:
	call ClearSprites
	farcall _Pokedex_JustWhiteOutBG
	ld a, [wTownMapCursorLandmark]
	cp KANTO_REGION
	jr z, .KantoGFX
	cp ORANGE_REGION
	jr z, .OrangeGFX
	call FillJohtoMap
	call .PlaceString_MonsNest
	call TownMapPals
	call TownMapJohtoFlips
.FinishGFX
	hlbgcoord 0, 0
	call TownMapBGUpdate
	ld b, CGB_POKEDEX_AREA_PALS
	call GetCGBLayout
	call SetPalettes
	xor a
	ld [hBGMapMode], a
	ret

.KantoGFX:
	call FillKantoMap
	call .PlaceString_MonsNest
	call TownMapPals
	call TownMapKantoFlips
	jr .FinishGFX

.OrangeGFX:
	call FillOrangeMap
	call .PlaceString_MonsNest
	call TownMapPals
	call TownMapOrangeFlips
	jr .FinishGFX

; 91dcd

.BlinkNestIcons: ; 91dcd
	ld a, [hVBlankCounter]
	ld e, a
	and $f
	ret nz
	ld a, e
	and $10
	jr nz, .copy_sprites
	jp ClearSprites

.copy_sprites
	hlcoord 0, 0
	ld de, Sprites
	ld bc, SpritesEnd - Sprites
	jp CopyBytes

; 91de9

.PlaceString_MonsNest: ; 91de9
	hlcoord 0, 0
	ld bc, SCREEN_WIDTH
	ld a, " "
	call ByteFill
	hlcoord 0, 1
	ld a, $6
	ld [hli], a
	ld bc, SCREEN_WIDTH - 2
	ld a, $7
	call ByteFill
	ld [hl], $17
	call GetPokemonName
	hlcoord 2, 0
	call PlaceString
	ld h, b
	ld l, c
	ld de, .String_SNest
	jp PlaceString

; 91e16

.String_SNest:
	db "'s Nest@"
; 91e1e

.GetAndPlaceNest: ; 91e1e
	ld a, [wTownMapCursorLandmark]
	ld e, a
	farcall FindNest ; load nest landmarks into TileMap[0,0]
	decoord 0, 0
	ld hl, Sprites
.nestloop
	ld a, [de]
	and a
	jr z, .done_nest
	push de
	ld e, a
	push hl
	farcall GetLandmarkCoords
	pop hl
	; load into OAM
	ld a, d
	sub 4
	ld [hli], a
	ld a, e
	sub 4
	ld [hli], a
	ld a, $7f ; nest icon in this context
	ld [hli], a
	xor a
	ld [hli], a
	; next
	pop de
	inc de
	jr .nestloop

.done_nest
	ld hl, Sprites
	decoord 0, 0
	ld bc, SpritesEnd - Sprites
	jp CopyBytes

; 91e5a

.HideNestsShowPlayer: ; 91e5a
	call .CheckPlayerLocation
	ret c
	ld a, [wTownMapPlayerIconLandmark]
	ld e, a
	farcall GetLandmarkCoords
	ld c, e
	ld b, d
	ld de, .PlayerOAM
	ld hl, Sprites
.ShowPlayerLoop:
	ld a, [de]
	cp $80
	jr z, .clear_oam
	add b
	ld [hli], a
	inc de
	ld a, [de]
	add c
	ld [hli], a
	inc de
	ld a, [de]
	add $78 ; where the player's sprite is loaded
	ld [hli], a
	inc de
	push bc
	ld c, PAL_OW_RED
	ld a, [PlayerGender]
	bit 0, a
	jr z, .got_gender
	ld c, PAL_OW_GREEN
.got_gender
	ld a, c
	ld [hli], a
	pop bc
	jr .ShowPlayerLoop

.clear_oam
	ld hl, Sprites + 4 * 4
	ld bc, SpritesEnd - (Sprites + 4 * 4)
	xor a
	jp ByteFill

; 91e9c

.PlayerOAM: ; 91e9c
	db -1 * 8, -1 * 8,  0 ; top left
	db -1 * 8,  0 * 8,  1 ; top right
	db  0 * 8, -1 * 8,  2 ; bottom left
	db  0 * 8,  0 * 8,  3 ; bottom right
	db $80 ; terminator
; 91ea9

.CheckPlayerLocation: ; 91ea9
; Don't show the player's sprite if you're
; not in the same region as what's currently
; on the screen.
	ld a, [wTownMapPlayerIconLandmark]
	cp SHAMOUTI_LANDMARK
	jr nc, .player_in_orange
	cp KANTO_LANDMARK
	jr nc, .player_in_kanto
	ld a, [wTownMapCursorLandmark]
	and a ; cp JOHTO_REGION
	jr nz, .clear
.ok
	and a
	ret

.player_in_kanto
	ld a, [wTownMapCursorLandmark]
	cp KANTO_REGION
	jr nz, .clear
	jr .ok

.player_in_orange
	ld a, [wTownMapCursorLandmark]
	cp ORANGE_REGION
	jr nz, .clear
	jr .ok

.clear
	ld hl, Sprites
	ld bc, SpritesEnd - Sprites
	xor a
	call ByteFill
	scf
	ret

; 91ed0

.GetPlayerOrFastShipIcon: ; 91ed0
	ld a, [wTownMapPlayerIconLandmark]
	cp FAST_SHIP
	jr z, .FastShip
	cp SINJOH_RUINS
	jr z, .Sinjoh
	cp MYSTRI_STAGE
	jr z, .Sinjoh
	farjp GetPlayerIcon

.FastShip:
	ld de, FastShipGFX
	ld b, BANK(FastShipGFX)
	ret

.Sinjoh:
	ld de, SinjohRuinsArrowGFX
	ld b, BANK(SinjohRuinsArrowGFX)
	ret

; 91ee4

TownMapBGUpdate: ; 91ee4
; Update BG Map tiles and attributes

; BG Map address
	ld a, l
	ld [hBGMapAddress], a
	ld a, h
	ld [hBGMapAddress + 1], a
; BG Map mode 2 (palettes)
	ld a, 2
	ld [hBGMapMode], a
; The BG Map is updated in thirds, so we wait
; 3 frames to update the whole screen's palettes.
	ld c, 3
	call DelayFrames
; Update BG Map tiles
	call WaitBGMap
; Turn off BG Map update
	xor a
	ld [hBGMapMode], a
	ret

; 91eff

FillJohtoMap: ; 91eff
	ld de, JohtoMap
	jr FillTownMap

FillOrangeMap:
	ld de, OrangeMap
	call FillTownMap
	eventflagcheck EVENT_VISITED_FARAWAY_ISLAND
	ret nz
	ld a, $a
	hlcoord 1, 12
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hl], a
	hlcoord 5, 13
	ld [hl], a
	hlcoord 2, 14
	ld [hli], a
	ld [hli], a
	inc hl
	ld [hl], a
	hlcoord 2, 15
	ld [hli], a
	ld [hli], a
	inc hl
	ld [hl], a
	hlcoord 5, 16
	ld [hl], a
	ret

FillKantoMap: ; 91f04
	ld de, KantoMap
FillTownMap: ; 91f07
	hlcoord 0, 0
.loop
	ld a, [de]
	cp -1
	ret z
	; [de] == yxTTTTTT
	ld a, [de]
	and %00111111
	; a == 00TTTTTT
	ld [hli], a
	inc de
	jr .loop

; 91f13

TownMapPals: ; 91f13
; Assign palettes based on tile ids
	hlcoord 0, 0
	decoord 0, 0, AttrMap
	ld bc, SCREEN_WIDTH * SCREEN_HEIGHT
.loop
	ld a, [hli]
	push hl
	cp $40 ; tiles in PokegearGFX (after TownMapGFX) use palette 0
	jr nc, .pal0
	call GetNextTownMapTilePalette
	jr .update
.pal0
	xor a
.update
	pop hl
	ld [de], a
	inc de
	dec bc
	ld a, b
	or c
	jr nz, .loop
	ret
; 91f7b

GetNextTownMapTilePalette:
; The palette data is condensed to nybbles, least-significant first.
	ld hl, .PalMap
	srl a
	jr c, .odd
; Even-numbered tile ids take the bottom nybble...
	add l
	ld l, a
	ld a, h
	adc 0
	ld h, a
	ld a, [hl]
	and %111
	ret

.odd
; ...and odd ids take the top.
	add l
	ld l, a
	ld a, h
	adc 0
	ld h, a
	ld a, [hl]
	swap a
	and %111
	ret

.PalMap:
townmappals: MACRO
rept _NARG / 2
	dn \2, \1
	shift
	shift
endr
endm
	townmappals 2, 2, 2, 3, 3, 6, 1, 1, 4, 4, 4, 5, 6, 7, 7, 6
	townmappals 2, 2, 2, 3, 3, 6, 1, 1, 4, 4, 4, 6, 4, 4, 1, 1
	townmappals 2, 2, 2, 6, 6, 6, 1, 1, 4, 4, 4, 7, 2, 4, 1, 1
	townmappals 2, 2, 2, 2, 4, 4, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0

TownMapJohtoFlips:
	decoord 0, 0, JohtoMap
	jr TownMapFlips

TownMapKantoFlips:
	decoord 0, 0, KantoMap
	jr TownMapFlips

TownMapOrangeFlips:
	decoord 0, 0, OrangeMap
TownMapFlips:
	hlcoord 0, 0, AttrMap
	ld bc, SCREEN_WIDTH * SCREEN_HEIGHT
.loop
	; [de] == YXtttttt
	ld a, [de]
	and %11000000
	srl a
	; a == 0YX00000
	or [hl]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or c
	jr nz, .loop
	ret

TownMapMon: ; 91f7b
; Draw the FlyMon icon at town map location in

; Get FlyMon species
	ld a, [CurPartyMon]
	ld hl, PartySpecies
	ld e, a
	ld d, $0
	add hl, de
	ld a, [hl]
	ld [wd265], a
; Get FlyMon icon
	ld e, 8 ; starting tile in VRAM
	farcall PokegearFlyMap_GetMonIcon
; Animation/palette
	depixel 0, 0
	ld a, SPRITE_ANIM_INDEX_PARTY_MON
	call _InitSpriteAnimStruct
	ld hl, SPRITEANIMSTRUCT_TILE_ID
	add hl, bc
	ld [hl], $8
	ld hl, SPRITEANIMSTRUCT_ANIM_SEQ_ID
	add hl, bc
	ld [hl], SPRITE_ANIM_SEQ_NULL
	ret

; 91fa6

TownMapPlayerIcon: ; 91fa6
; Draw the player icon at town map location in a
	push af
	farcall GetPlayerIcon
; Standing icon
	ld hl, VTiles0 tile $10
	ld c, 4 ; # tiles
	call Request2bpp
; Walking icon
	ld hl, $c0
	add hl, de
	ld d, h
	ld e, l
	ld hl, VTiles0 tile $14
	ld c, 4 ; # tiles
	call Request2bpp
; Animation/palette
	depixel 0, 0
	ld b, SPRITE_ANIM_INDEX_RED_WALK ; Male
	ld a, [PlayerGender]
	bit 0, a
	jr z, .got_gender
	ld b, SPRITE_ANIM_INDEX_BLUE_WALK ; Female
.got_gender
	ld a, b
	call _InitSpriteAnimStruct
	ld hl, SPRITEANIMSTRUCT_TILE_ID
	add hl, bc
	ld [hl], $10
	pop af
	ld e, a
	push bc
	farcall GetLandmarkCoords
	pop bc
	ld hl, SPRITEANIMSTRUCT_XCOORD
	add hl, bc
	ld [hl], e
	ld hl, SPRITEANIMSTRUCT_YCOORD
	add hl, bc
	ld [hl], d
	ret

; 0x91ff2

LoadTownMapGFX: ; 91ff2
	ld hl, TownMapGFX
	ld de, VTiles2
	lb bc, BANK(TownMapGFX), $40
	jp DecompressRequest2bpp

; 91fff

JohtoMap: ; 91fff
INCBIN "gfx/town_map/johto.bin"
; 92168

KantoMap: ; 92168
INCBIN "gfx/town_map/kanto.bin"
; 922d1

OrangeMap:
INCBIN "gfx/town_map/orange.bin"

PokedexNestIconGFX: ; 922d1
INCBIN "gfx/town_map/dexmap_nest_icon.2bpp"

PokegearGFX: ; 1de2e4
INCBIN "gfx/pokegear/pokegear.2bpp.lz"

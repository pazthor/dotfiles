#include QMK_KEYBOARD_H
#include "version.h"

#ifndef ZSA_SAFE_RANGE
#define ZSA_SAFE_RANGE SAFE_RANGE
#endif


enum custom_keycodes {
  RGB_SLD = ZSA_SAFE_RANGE,
  HSV_36_244_245,
  HSV_131_255_255,
};



const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {
  [0] = LAYOUT_ergodox_pretty(
    KC_DELETE,      KC_1,           KC_2,           KC_3,           KC_4,           KC_5,           KC_TRANSPARENT,                                 KC_PAGE_UP,     KC_6,           KC_7,           KC_8,           KC_9,           KC_0,           KC_MINUS,
    KC_TAB,         KC_Q,           KC_W,           KC_E,           KC_R,           KC_T,           KC_TRANSPARENT,                                 KC_PSCR,        KC_Y,           KC_U,           KC_I,           KC_O,           KC_P,           KC_BSLS,
    KC_RIGHT_CTRL,  KC_A,           KC_S,           KC_D,           KC_F,           KC_G,                                                                           KC_H,           KC_J,           KC_K,           KC_L,           KC_SCLN,        MT(MOD_RCTL, KC_QUOTE),
    KC_LEFT_SHIFT,  KC_Z,           KC_X,           KC_C,           KC_V,           KC_B,           KC_TRANSPARENT,                                 KC_PGDN,        KC_N,           KC_M,           KC_COMMA,       KC_DOT,         KC_SLASH,       KC_RIGHT_SHIFT,
    MO(1),          MO(3),          MO(2),          LGUI(LSFT(KC_TAB)),LGUI(KC_TAB),                                                                                                   LGUI(KC_LEFT),  LGUI(KC_RIGHT), KC_TRANSPARENT, KC_TRANSPARENT, KC_ENTER,
                                                                                                    RALT(RCTL(KC_RIGHT_GUI)),LALT(RCTL(KC_LEFT_GUI)),KC_HOME,        KC_END,
                                                                                                                    KC_TRANSPARENT, KC_TRANSPARENT,
                                                                                    KC_SPACE,       KC_LEFT_GUI,    KC_LEFT_ALT,    KC_RIGHT_ALT,   KC_LEFT_GUI,    KC_BSPC
  ),
  [1] = LAYOUT_ergodox_pretty(
    KC_TRANSPARENT, KC_F1,          KC_F2,          KC_F3,          KC_F4,          KC_F5,          KC_F6,                                          KC_F7,          KC_F8,          KC_F9,          KC_F10,         KC_F11,         KC_F12,         KC_DELETE,
    KC_TRANSPARENT, KC_TRANSPARENT, KC_GRAVE,       KC_LCBR,        KC_RCBR,        KC_TRANSPARENT, KC_TRANSPARENT,                                 KC_TRANSPARENT, KC_PLUS,        KC_EXLM,        KC_DLR,         KC_AMPR,        KC_TRANSPARENT, KC_TRANSPARENT,
    KC_TRANSPARENT, KC_TRANSPARENT, KC_BSLS,        KC_LPRN,        KC_RPRN,        KC_TRANSPARENT,                                                                 KC_QUES,        KC_AT,          KC_PERC,        KC_ASTR,        KC_QUOTE,       KC_TRANSPARENT,
    MOD_LSFT,       KC_TRANSPARENT, KC_TILD,        KC_LBRC,        KC_RBRC,        KC_TRANSPARENT, KC_TRANSPARENT,                                 KC_TRANSPARENT, KC_HASH,        KC_CIRC,        KC_PIPE,        KC_EQUAL,       KC_TRANSPARENT, KC_TRANSPARENT,
    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,                                                                                                 KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,
                                                                                                    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,
                                                                                                                    KC_TRANSPARENT, KC_TRANSPARENT,
                                                                                    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT
  ),
  [2] = LAYOUT_ergodox_pretty(
    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,                                 KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,
    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_MS_UP,       KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,                                 KC_TRANSPARENT, LGUI(KC_6),     LGUI(KC_7),     LGUI(KC_8),     LGUI(KC_9),     KC_TRANSPARENT, KC_TRANSPARENT,
    KC_TRANSPARENT, KC_TRANSPARENT, KC_MS_LEFT,     KC_MS_DOWN,     KC_MS_RIGHT,    KC_TRANSPARENT,                                                                 KC_LEFT,        KC_DOWN,        KC_UP,          KC_RIGHT,       KC_TRANSPARENT, KC_MEDIA_PLAY_PAUSE,
    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,                                 KC_TRANSPARENT, KC_HOME,        KC_PGDN,        KC_PAGE_UP,     KC_END,         KC_TRANSPARENT, KC_TRANSPARENT,
    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_MS_BTN1,     KC_MS_BTN2,                                                                                                     KC_AUDIO_VOL_UP,KC_AUDIO_VOL_DOWN,KC_AUDIO_MUTE,  KC_TRANSPARENT, KC_TRANSPARENT,
                                                                                                    KC_TRANSPARENT, HSV_36_244_245, KC_TRANSPARENT, KC_TRANSPARENT,
                                                                                                                    HSV_131_255_255,KC_TRANSPARENT,
                                                                                    RGB_VAI,        RGB_VAD,        RGB_HUI,        KC_MEDIA_PLAY_PAUSE,KC_MEDIA_STOP,  RGB_SLD
  ),
  [3] = LAYOUT_ergodox_pretty(
    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,                                 KC_TRANSPARENT, KC_KP_EQUAL,    KC_KP_SLASH,    KC_KP_ASTERISK, KC_KP_MINUS,    KC_TRANSPARENT, KC_TRANSPARENT,
    KC_TRANSPARENT, KC_TRANSPARENT, KC_LABK,        KC_RABK,        KC_UNDS,        KC_TRANSPARENT, KC_TRANSPARENT,                                 KC_TRANSPARENT, KC_7,           KC_8,           KC_9,           KC_KP_PLUS,     KC_TRANSPARENT, KC_TRANSPARENT,
    KC_TRANSPARENT, KC_EXLM,        KC_MINUS,       KC_PLUS,        KC_EQUAL,       KC_TRANSPARENT,                                                                 KC_4,           KC_5,           KC_6,           KC_KP_ENTER,    KC_TRANSPARENT, KC_TRANSPARENT,
    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,                                 KC_TRANSPARENT, KC_1,           KC_2,           KC_3,           KC_LPRN,        KC_RPRN,        KC_TRANSPARENT,
    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,                                                                                                 KC_0,           KC_DOT,         KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,
                                                                                                    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,
                                                                                                                    KC_TRANSPARENT, KC_TRANSPARENT,
                                                                                    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT
  ),
};



const uint16_t PROGMEM combo0[] = { KC_J, KC_K, COMBO_END};

combo_t key_combos[COMBO_COUNT] = {
    COMBO(combo0, KC_ESCAPE),
};



extern rgb_config_t rgb_matrix_config;

RGB hsv_to_rgb_with_value(HSV hsv) {
  RGB rgb = hsv_to_rgb( hsv );
  float f = (float)rgb_matrix_config.hsv.v / UINT8_MAX;
  return (RGB){ f * rgb.r, f * rgb.g, f * rgb.b };
}

void keyboard_post_init_user(void) {
  rgb_matrix_enable();
}

const uint8_t PROGMEM ledmap[][RGB_MATRIX_LED_COUNT][3] = {
    [0] = { {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {169,120,255}, {169,120,255}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {5,255,213}, {169,120,255}, {0,204,255}, {12,225,241}, {5,255,213} },

    [1] = { {85,203,158}, {85,203,158}, {85,203,158}, {85,203,158}, {85,203,158}, {131,255,255}, {146,224,255}, {146,224,255}, {146,224,255}, {134,255,213}, {0,245,245}, {10,225,255}, {10,225,255}, {10,225,255}, {219,255,255}, {219,255,255}, {219,255,255}, {219,255,255}, {219,255,255}, {219,255,255}, {41,255,255}, {32,255,234}, {41,255,255}, {32,255,234}, {85,203,158}, {85,203,158}, {85,203,158}, {85,203,158}, {85,203,158}, {134,255,213}, {76,175,192}, {76,175,192}, {146,224,255}, {134,255,213}, {134,255,213}, {76,175,192}, {76,175,192}, {146,224,255}, {134,255,213}, {134,255,213}, {76,175,192}, {76,175,192}, {146,224,255}, {134,255,213}, {74,255,255}, {74,255,255}, {74,255,255}, {74,255,255} },

    [2] = { {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {197,175,192}, {139,238,166}, {0,0,0}, {197,175,192}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {169,120,255}, {0,0,0}, {169,120,255}, {169,120,255}, {0,204,255}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {169,120,255}, {0,0,0}, {0,0,0}, {0,0,0}, {169,120,255}, {169,120,255}, {169,120,255}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {32,255,234}, {32,255,234}, {0,0,0}, {0,0,0} },

    [3] = { {139,164,158}, {139,164,158}, {139,164,158}, {139,164,158}, {0,0,0}, {131,255,255}, {131,255,255}, {131,255,255}, {139,164,158}, {0,0,0}, {131,255,255}, {131,255,255}, {131,255,255}, {0,245,245}, {0,0,0}, {131,255,255}, {131,255,255}, {131,255,255}, {74,255,255}, {74,255,255}, {131,255,255}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0} },

};

void set_layer_color(int layer) {
  for (int i = 0; i < RGB_MATRIX_LED_COUNT; i++) {
    HSV hsv = {
      .h = pgm_read_byte(&ledmap[layer][i][0]),
      .s = pgm_read_byte(&ledmap[layer][i][1]),
      .v = pgm_read_byte(&ledmap[layer][i][2]),
    };
    if (!hsv.h && !hsv.s && !hsv.v) {
        rgb_matrix_set_color( i, 0, 0, 0 );
    } else {
        RGB rgb = hsv_to_rgb_with_value(hsv);
        rgb_matrix_set_color(i, rgb.r, rgb.g, rgb.b);
    }
  }
}

bool rgb_matrix_indicators_user(void) {
  if (rawhid_state.rgb_control) {
      return false;
  }
  if (!keyboard_config.disable_layer_led) { 
    switch (biton32(layer_state)) {
      case 0:
        set_layer_color(0);
        break;
      case 1:
        set_layer_color(1);
        break;
      case 2:
        set_layer_color(2);
        break;
      case 3:
        set_layer_color(3);
        break;
     default:
        if (rgb_matrix_get_flags() == LED_FLAG_NONE) {
          rgb_matrix_set_color_all(0, 0, 0);
        }
    }
  } else {
    if (rgb_matrix_get_flags() == LED_FLAG_NONE) {
      rgb_matrix_set_color_all(0, 0, 0);
    }
  }

  return true;
}




bool process_record_user(uint16_t keycode, keyrecord_t *record) {
  switch (keycode) {

    case RGB_SLD:
      if (record->event.pressed) {
        rgblight_mode(1);
      }
      return false;
    case HSV_36_244_245:
      if (record->event.pressed) {
        rgblight_mode(1);
        rgblight_sethsv(36,244,245);
      }
      return false;
    case HSV_131_255_255:
      if (record->event.pressed) {
        rgblight_mode(1);
        rgblight_sethsv(131,255,255);
      }
      return false;
  }
  return true;
}

uint8_t layer_state_set_user(uint8_t state) {
    uint8_t layer = biton(state);
  ergodox_board_led_off();
  ergodox_right_led_1_off();
  ergodox_right_led_2_off();
  ergodox_right_led_3_off();
  switch (layer) {
    case 1:
      ergodox_right_led_1_on();
      break;
    case 2:
      ergodox_right_led_2_on();
      break;
    case 3:
      ergodox_right_led_3_on();
      break;
    case 4:
      ergodox_right_led_1_on();
      ergodox_right_led_2_on();
      break;
    case 5:
      ergodox_right_led_1_on();
      ergodox_right_led_3_on();
      break;
    case 6:
      ergodox_right_led_2_on();
      ergodox_right_led_3_on();
      break;
    case 7:
      ergodox_right_led_1_on();
      ergodox_right_led_2_on();
      ergodox_right_led_3_on();
      break;
    default:
      break;
  }
  return state;
};


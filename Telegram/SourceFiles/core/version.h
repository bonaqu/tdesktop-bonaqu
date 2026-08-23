/*
This file is part of Telegram Desktop,
the official desktop application for the Telegram messaging service.

For license and copyright information please follow this link:
https://github.com/telegramdesktop/tdesktop/blob/master/LEGAL
*/
#pragma once

#include "base/const_string.h"

#define TDESKTOP_REQUESTED_ALPHA_VERSION (0ULL)

#ifdef TDESKTOP_ALLOW_CLOSED_ALPHA
#define TDESKTOP_ALPHA_VERSION TDESKTOP_REQUESTED_ALPHA_VERSION
#else // TDESKTOP_ALLOW_CLOSED_ALPHA
#define TDESKTOP_ALPHA_VERSION (0ULL)
#endif // TDESKTOP_ALLOW_CLOSED_ALPHA

// Bonaqu Client has its own Windows application identity and must not share
// installer/update identity with the official Telegram Desktop application.
constexpr auto AppId = "{D4195297-1CA0-47BB-9EB9-8239E93692A9}"_cs;
constexpr auto AppNameOld = "Bonaqu Client Legacy"_cs;
constexpr auto AppName = "Bonaqu Client"_cs;
constexpr auto AppFile = "BonaquClient"_cs;
constexpr auto AppVersion = 7001001;
constexpr auto AppVersionStr = "7.1.1";
constexpr auto AppBetaVersion = false;
constexpr auto AppAlphaVersion = TDESKTOP_ALPHA_VERSION;

/*
This file is part of Telegram Desktop,
the official desktop application for the Telegram messaging service.

For license and copyright information please follow this link:
https://github.com/telegramdesktop/tdesktop/blob/master/LEGAL
*/
#include "boxes/about_box.h"

#include "base/platform/base_platform_info.h"
#include "core/application.h"
#include "core/core_settings.h"
#include "core/file_utilities.h"
#include "core/update_checker.h"
#include "core/version.h"
#include "lang/lang_keys.h"
#include "mtproto/mtproto_proxy_data.h"
#include "settings.h"
#include "ui/boxes/confirm_box.h"
#include "ui/painter.h"
#include "ui/rect.h"
#include "ui/text/text_utilities.h"
#include "ui/vertical_list.h"
#include "ui/widgets/buttons.h"
#include "ui/wrap/vertical_layout.h"
#include "styles/style_layers.h"
#include "styles/style_boxes.h"
#include "styles/style_channel_earn.h"
#include "styles/style_chat.h"
#include "styles/style_dialogs.h"
#include "styles/style_menu_icons.h"
#include "styles/style_premium.h"
#include "styles/style_settings.h"

#include <QtGui/QGuiApplication>
#include <QtGui/QClipboard>

namespace {

rpl::producer<TextWithEntities> Text1() {
	return tr::lng_about_text1(
		lt_api_link,
		tr::lng_about_text1_api(tr::url(u"https://core.telegram.org/api"_q)),
		tr::marked);
}

rpl::producer<TextWithEntities> Text2() {
	return tr::lng_about_text2(
		lt_gpl_link,
		rpl::single(tr::link(
			"GNU GPL",
			"https://github.com/telegramdesktop/tdesktop/blob/master/LICENSE")),
		lt_github_link,
		rpl::single(tr::link(
			"GitHub",
			"https://github.com/telegramdesktop/tdesktop")),
		tr::marked);
}

rpl::producer<TextWithEntities> Text3() {
	return tr::lng_about_text3(
		lt_faq_link,
		tr::lng_about_text3_faq(tr::url(telegramFaqLink())),
		tr::marked);
}

QString BonaquProxyTypeText() {
	const auto &proxy = Core::App().settings().proxy();
	if (!proxy.isEnabled()) {
		return u"disabled"_q;
	}
	using Type = MTP::ProxyData::Type;
	switch (proxy.selected().type) {
	case Type::None: return u"none"_q;
	case Type::Socks5: return u"SOCKS5"_q;
	case Type::Http: return u"HTTP"_q;
	case Type::Mtproto: return u"MTProto"_q;
	case Type::Web: return u"WEB Proxy"_q;
	}
	Unexpected("Proxy type in Bonaqu diagnostics.");
}

QString BonaquSafeDiagnostics() {
	const auto architecture = Platform::IsWindowsARM64()
		? u"arm64"_q
		: Platform::IsWindows64Bit()
		? u"x64"_q
		: Platform::IsWindows32Bit()
		? u"x86"_q
		: u"other"_q;
	const auto profileMode = cWorkingDir().isEmpty()
		? u"default"_q
		: u"isolated/custom workdir"_q;

	return u"Bonaqu Client safe diagnostics\n"
		u"Version: %1\n"
		u"Architecture: %2\n"
		u"Profile mode: %3\n"
		u"Proxy: %4\n"
		u"Auto-update: disabled in Bonaqu build\n"
		u"Crash reporting: disabled in Bonaqu build\n"
		u"API application: BonaquDesktop26 / bonaqu26\n"
		u"Source: https://github.com/bonaqu/tdesktop-bonaqu"
		.arg(currentVersionText())
		.arg(architecture)
		.arg(profileMode)
		.arg(BonaquProxyTypeText());
}

} // namespace

void AboutBox(not_null<Ui::GenericBox*> box) {
	box->setTitle(u"Bonaqu Client"_q);

	auto layout = box->verticalLayout();

	const auto version = layout->add(
		object_ptr<Ui::LinkButton>(
			box,
			tr::lng_about_version(
				tr::now,
				lt_version,
				currentVersionText()),
			st::aboutVersionLink),
		QMargins(
			st::boxRowPadding.left(),
			-st::lineWidth * 3,
			st::boxRowPadding.right(),
			st::boxRowPadding.bottom()));
	version->setClickedCallback([=] {
		if (cRealAlphaVersion()) {
			auto url = u"https://tdesktop.com/"_q;
			if (Platform::IsWindows32Bit()) {
				url += u"win/%1.zip"_q;
			} else if (Platform::IsWindows64Bit()) {
				url += u"win64/%1.zip"_q;
			} else if (Platform::IsWindowsARM64()) {
				url += u"winarm/%1.zip"_q;
			} else if (Platform::IsMac()) {
				url += u"mac/%1.zip"_q;
			} else if (Platform::IsLinux()) {
				url += u"linux/%1.tar.xz"_q;
			} else {
				Unexpected("Platform value.");
			}
			url = url.arg(u"talpha%1_%2"_q
				.arg(cRealAlphaVersion())
				.arg(Core::countAlphaVersionSignature(cRealAlphaVersion())));

			QGuiApplication::clipboard()->setText(url);

			box->getDelegate()->show(
				Ui::MakeInformBox(
					"The link to the current private alpha "
					"version of Telegram Desktop was copied "
					"to the clipboard."));
		} else {
			File::OpenUrl(Core::App().changelogLink());
		}
	});

	Ui::AddSkip(layout, st::aboutTopSkip);

	const auto forkInfo = layout->add(
		object_ptr<Ui::FlatLabel>(
			box,
			rpl::single(u"Unofficial Telegram client by bonaqu. Built on Telegram Desktop and using the Telegram API. BonaquDesktop26 / bonaqu26."_q),
			st::aboutLabel),
		st::boxRowPadding);
	forkInfo->setAttribute(Qt::WA_TransparentForMouseEvents);
	Ui::AddSkip(layout, st::aboutSkip);

	const auto source = layout->add(
		object_ptr<Ui::LinkButton>(
			box,
			u"Bonaqu Client source code"_q,
			st::aboutVersionLink),
		st::boxRowPadding);
	source->setClickedCallback([] {
		File::OpenUrl(u"https://github.com/bonaqu/tdesktop-bonaqu"_q);
	});
	Ui::AddSkip(layout, st::aboutSkip);

	const auto toolsTitle = layout->add(
		object_ptr<Ui::FlatLabel>(
			box,
			rpl::single(u"Bonaqu Control Center"_q),
			st::boxTitle),
		st::boxRowPadding);
	toolsTitle->setAttribute(Qt::WA_TransparentForMouseEvents);
	Ui::AddSkip(layout, st::aboutSkip);

	const auto diagnostics = layout->add(
		object_ptr<Ui::LinkButton>(
			box,
			u"Copy safe connection diagnostics"_q,
			st::aboutVersionLink),
		st::boxRowPadding);
	diagnostics->setClickedCallback([=] {
		QGuiApplication::clipboard()->setText(BonaquSafeDiagnostics());
		box->getDelegate()->show(
			Ui::MakeInformBox(
				u"Bonaqu diagnostics copied. The summary excludes proxy hosts, credentials, account identifiers and absolute profile paths."_q));
	});
	Ui::AddSkip(layout, st::aboutSkip);

	const auto dataFolder = layout->add(
		object_ptr<Ui::LinkButton>(
			box,
			u"Open Bonaqu data folder"_q,
			st::aboutVersionLink),
		st::boxRowPadding);
	dataFolder->setClickedCallback([] {
		const auto path = cWorkingDir().isEmpty() ? cExeDir() : cWorkingDir();
		File::Launch(path);
	});
	Ui::AddSkip(layout, st::aboutSkip);

	const auto roadmap = layout->add(
		object_ptr<Ui::LinkButton>(
			box,
			u"Bonaqu features and upstream policy"_q,
			st::aboutVersionLink),
		st::boxRowPadding);
	roadmap->setClickedCallback([] {
		File::OpenUrl(u"https://github.com/bonaqu/tdesktop-bonaqu/blob/dev/docs/bonaqu-features.md"_q);
	});
	Ui::AddSkip(layout, st::aboutSkip);

	const auto addText = [&](rpl::producer<TextWithEntities> text) {
		const auto label = layout->add(
			object_ptr<Ui::FlatLabel>(box, std::move(text), st::aboutLabel),
			st::boxRowPadding);
		label->setLinksTrusted();
		Ui::AddSkip(layout, st::aboutSkip);
	};

	addText(Text1());
	addText(Text2());
	addText(Text3());

	box->addButton(tr::lng_close(), [=] { box->closeBox(); });

	box->setWidth(st::aboutWidth);
}

QString telegramFaqLink() {
	const auto result = u"https://telegram.org/faq"_q;
	const auto langpacked = [&](const char *language) {
		return result + '/' + language;
	};
	const auto current = Lang::Id();
	for (const auto language : { "de", "es", "it", "ko" }) {
		if (current.startsWith(QLatin1String(language))) {
			return langpacked(language);
		}
	}
	if (current.startsWith(u"pt-br"_q)) {
		return langpacked("br");
	}
	return result;
}

QString currentVersionText() {
	auto result = QString::fromLatin1(AppVersionStr);
	if (cAlphaVersion()) {
		result += u" alpha %1"_q.arg(cAlphaVersion() % 1000);
	} else if (AppBetaVersion) {
		result += " beta";
	}
	if (Platform::IsWindows64Bit()) {
		result += " x64";
	} else if (Platform::IsWindowsARM64()) {
		result += " arm64";
	}
#ifdef _DEBUG
	result += " DEBUG";
#endif
	return result;
}

void ArchiveHintBox(
		not_null<Ui::GenericBox*> box,
		bool unarchiveOnNewMessage,
		Fn<void()> onUnarchive) {
	box->setNoContentMargin(true);

	const auto content = box->verticalLayout().get();

	Ui::AddSkip(content);
	Ui::AddSkip(content);
	Ui::AddSkip(content);
	{
		const auto &icon = st::dialogsArchiveUserpic;
		const auto rect = Rect(icon.size() * 2);
		auto owned = object_ptr<Ui::RpWidget>(content);
		owned->resize(rect.size());
		owned->setNaturalWidth(rect.width());
		const auto widget = box->addRow(std::move(owned), style::al_top);
		widget->paintRequest(
		) | rpl::on_next([=] {
			auto p = Painter(widget);
			auto hq = PainterHighQualityEnabler(p);
			p.setPen(Qt::NoPen);
			p.setBrush(st::activeButtonBg);
			p.drawEllipse(rect);
			icon.paintInCenter(p, rect);
		}, widget->lifetime());
	}
	Ui::AddSkip(content);
	Ui::AddSkip(content);
	box->addRow(
		object_ptr<Ui::FlatLabel>(
			content,
			tr::lng_archive_hint_title(),
			st::boxTitle),
		style::al_top);
	Ui::AddSkip(content);
	Ui::AddSkip(content);
	{
		const auto label = box->addRow(
			object_ptr<Ui::FlatLabel>(
				content,
				(unarchiveOnNewMessage
						? tr::lng_archive_hint_about_unmuted
						: tr::lng_archive_hint_about)(
					lt_link,
					tr::lng_archive_hint_about_link(
						lt_emoji,
						rpl::single(
							Ui::Text::IconEmoji(&st::textMoreIconEmoji)),
						tr::rich
					) | rpl::map([](TextWithEntities text) {
						return tr::link(std::move(text), 1);
					}),
					tr::rich),
				st::channelEarnHistoryRecipientLabel));
		label->resizeToWidth(box->width()
			- rect::m::sum::h(st::boxRowPadding));
		label->setLink(
			1,
			std::make_shared<GenericClickHandler>([=](ClickContext context) {
				if (context.button == Qt::LeftButton) {
					onUnarchive();
				}
			}));
	}
	Ui::AddSkip(content);
	Ui::AddSkip(content);
	Ui::AddSkip(content);
	Ui::AddSkip(content);
	{
		const auto padding = QMargins(
			st::settingsButton.padding.left(),
			st::boxRowPadding.top(),
			st::boxRowPadding.right(),
			st::boxRowPadding.bottom());
		const auto addEntry = [&](
				rpl::producer<QString> title,
				rpl::producer<QString> about,
				const style::icon &icon) {
			const auto top = content->add(
				object_ptr<Ui::FlatLabel>(
					content,
					std::move(title),
					st::channelEarnSemiboldLabel),
				padding);
			Ui::AddSkip(content, st::channelEarnHistoryThreeSkip);
			content->add(
				object_ptr<Ui::FlatLabel>(
					content,
					std::move(about),
					st::channelEarnHistoryRecipientLabel),
				padding);
			const auto left = Ui::CreateChild<Ui::RpWidget>(
				box->verticalLayout().get());
			left->paintRequest(
			) | rpl::on_next([=] {
				auto p = Painter(left);
				icon.paint(p, 0, 0, left->width());
			}, left->lifetime());
			left->resize(icon.size());
			top->geometryValue(
			) | rpl::on_next([=](const QRect &g) {
				left->moveToLeft(
					(g.left() - left->width()) / 2,
					g.top() + st::channelEarnHistoryThreeSkip);
			}, left->lifetime());
		};
		addEntry(
			tr::lng_archive_hint_section_1(),
			tr::lng_archive_hint_section_1_info(),
			st::menuIconArchive);
		Ui::AddSkip(content);
		Ui::AddSkip(content);
		addEntry(
			tr::lng_archive_hint_section_2(),
			tr::lng_archive_hint_section_2_info(),
			st::menuIconStealth);
		Ui::AddSkip(content);
		Ui::AddSkip(content);
		addEntry(
			tr::lng_archive_hint_section_3(),
			tr::lng_archive_hint_section_3_info(),
			st::menuIconStoriesSavedSection);
		Ui::AddSkip(content);
		Ui::AddSkip(content);
	}
	Ui::AddSkip(content);
	Ui::AddSkip(content);
	Ui::AddSkip(content);
	{
		const auto &st = st::premiumPreviewDoubledLimitsBox;
		box->setStyle(st);
		auto button = object_ptr<Ui::RoundButton>(
			box,
			tr::lng_archive_hint_button(),
			st::defaultActiveButton);
		button->resizeToWidth(box->width()
			- st.buttonPadding.left()
			- st.buttonPadding.left());
		button->setClickedCallback([=] { box->closeBox(); });
		box->addButton(std::move(button));
	}
}


#include "AppFrame.h"
#include "Config.h"
#include "core/FileSystem.hpp"
#include "GameResource/ResourcePassword.hpp"
//TODO

using std::string_view_literals::operator ""sv;

namespace luastg {
	bool AppFrame::OnLoadLaunchScriptAndFiles() {
		constexpr std::string_view packages[]{
			"assets.pkg"sv,
			"language.pkg"sv,
			"scripts.pkg"sv,
		};
		for (auto const& pkg : packages) {
			core::SmartReference<core::IFileSystemArchive> archive;
			if (!core::IFileSystemArchive::createFromFile(pkg, archive.put())) {
				continue;
			}
			archive->setPassword(GetGameName());
			core::FileSystemManager::addFileSystem(pkg, archive.get());
		}
		return true;
	};

	bool AppFrame::OnLoadMainScriptAndFiles() {
		spdlog::info("[luastg] 加载入口点脚本");
		constexpr std::string_view entry_scripts[]{
			"core.lua"sv,
			"main.lua"sv,
			"src/main.lua"sv,
		};
		bool is_load = false;
		core::SmartReference<core::IData> src;
		for (auto& v : entry_scripts) {
			if (!core::FileSystemManager::readFile(v, src.put())) {
				continue;
			}
			if (SafeCallScript(static_cast<char const*>(src->data()), src->size(), v.data())) {
				spdlog::info("[luastg] 加载脚本'{}'", v);
				is_load = true;
				break;
			}
		}
		if (!is_load) {
			spdlog::error("[luastg] 找不到文件'{}'、'{}'或'{}'", entry_scripts[0], entry_scripts[1], entry_scripts[2]);
		}
		return true;
	}
}

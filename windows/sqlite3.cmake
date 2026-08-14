# Provisions the SQLite library that the desktop database layer needs (ADR-035).
#
# On desktop, sqflite runs through sqflite_common_ffi (ADR-031), which loads
# SQLite dynamically via the `sqlite3` package. Linux resolves that against the
# system libsqlite3; Windows has no system SQLite at all, so the DLL has to
# travel with the app or every history read and every save fails at runtime.
#
# Rather than commit a 3 MB binary, download the official build from sqlite.org
# once and verify it against the SHA3-256 hash published on the download page
# (sqlite.org lists SHA3-256, not SHA-256 — do not "fix" this to SHA256). The
# result is cached in windows/third_party/, which is git-ignored, so the
# download happens once per checkout and architecture.

set(SQLITE3_VERSION "3.53.4")
set(SQLITE3_YEAR "2026")
set(SQLITE3_BUILD "3530400")

# Flutter configures the Windows build with -A x64 / -A ARM64 / -A Win32, so
# CMAKE_GENERATOR_PLATFORM is the reliable architecture signal here.
set(_arch "${CMAKE_GENERATOR_PLATFORM}")
if(NOT _arch)
  set(_arch "${CMAKE_SYSTEM_PROCESSOR}")
endif()

if(_arch MATCHES "^(ARM64|arm64|aarch64)$")
  set(SQLITE3_ARCH "arm64")
  set(SQLITE3_SHA3 "4b2c43549b9c8d9b9eb4acf3dc524f05a1a0fb05364a93da2ad4dd9317c389c4")
elseif(_arch MATCHES "^(Win32|win32|X86|x86)$")
  set(SQLITE3_ARCH "x86")
  set(SQLITE3_SHA3 "64bf53d675ae2fcee57e180e8f59035e1b2b11ed5a2915450e26d0930a3cb9c8")
else()
  set(SQLITE3_ARCH "x64")
  set(SQLITE3_SHA3 "deddee963c810d1eeac3ce5e15c7c41da21a1c54d7a39cf54fbf577d2f50de3a")
endif()

set(SQLITE3_DIR "${CMAKE_CURRENT_SOURCE_DIR}/third_party/sqlite3/${SQLITE3_ARCH}-${SQLITE3_VERSION}")
set(SQLITE3_DLL "${SQLITE3_DIR}/sqlite3.dll")

if(NOT EXISTS "${SQLITE3_DLL}")
  if(CMAKE_VERSION VERSION_LESS 3.18)
    message(FATAL_ERROR
      "CMake ${CMAKE_VERSION} cannot extract archives (needs 3.18+).\n"
      "Either update CMake, or download\n"
      "  https://sqlite.org/${SQLITE3_YEAR}/sqlite-dll-win-${SQLITE3_ARCH}-${SQLITE3_BUILD}.zip\n"
      "manually and unpack sqlite3.dll to\n  ${SQLITE3_DIR}")
  endif()

  set(_url "https://sqlite.org/${SQLITE3_YEAR}/sqlite-dll-win-${SQLITE3_ARCH}-${SQLITE3_BUILD}.zip")
  set(_zip "${SQLITE3_DIR}/sqlite-dll.zip")

  message(STATUS "Fetching SQLite ${SQLITE3_VERSION} (${SQLITE3_ARCH}) from ${_url}")
  file(DOWNLOAD "${_url}" "${_zip}"
    EXPECTED_HASH SHA3_256=${SQLITE3_SHA3}
    TLS_VERIFY ON
    STATUS _download_status
    SHOW_PROGRESS)

  list(GET _download_status 0 _download_code)
  if(NOT _download_code EQUAL 0)
    list(GET _download_status 1 _download_message)
    file(REMOVE "${_zip}")
    message(FATAL_ERROR
      "Could not download SQLite: ${_download_message}\n"
      "If this machine has no internet access, fetch\n  ${_url}\n"
      "elsewhere and unpack sqlite3.dll to\n  ${SQLITE3_DIR}")
  endif()

  file(ARCHIVE_EXTRACT INPUT "${_zip}" DESTINATION "${SQLITE3_DIR}")
  file(REMOVE "${_zip}")

  if(NOT EXISTS "${SQLITE3_DLL}")
    message(FATAL_ERROR "SQLite archive did not contain sqlite3.dll: ${_url}")
  endif()
endif()

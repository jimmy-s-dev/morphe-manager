# YouTube Music의 Android Auto 목록 검증

Android Auto의 재생 화면과 목록 화면은 별도 경로를 사용한다. 휴대폰에서 음악 목록이 정상이어도 Auto에서는 팟캐스트 중심 목록이나 빈 재생목록이 표시될 수 있다. 매니저는 APK에 패치를 적용하는 도구이며, 목록 개선 코드는 별도 `morphe-patches` 저장소에 있다.

## 실험 패치

- 대상: 원본 YouTube Music **9.15.51** APK.
- 구현 저장소: `morphe-patches`, 작업 브랜치 `codex/android-auto-library`.
- 핵심 코드: `patches/.../music/misc/androidauto/playlists/RestoreAndroidAutoPlaylistsPatch.kt`, `extensions/music/.../RestoreAndroidAutoPlaylistsPatch.java`, `MusicHomeRenderer.java`.
- Auto의 최상위 목록을 재생목록 / 최근 감상 / 추천으로 구성한다. 로그인한 휴대폰 앱의 Library, history, Home 응답을 사용한다.
- 재생목록 항목은 곡 목록을 여는 폴더다. 목록 조회 자체는 재생 명령을 보내지 않는다.
- 긴 결과는 Android Binder 전송 크기에 맞춰 나누며, `더 보기` 폴더에서 이어서 탐색한다.
- 9.15.51에서 확인한 Home 카드 형식만 지원한다. 서버가 응답 형식을 변경하면 추가 대응이 필요하다. Premium의 순정 화면을 픽셀 단위로 복제하는 기능은 아니다.

기존 앱과 서명이 다르면 업데이트 설치가 불가능하다. 기존 앱을 삭제하지 말고 `Clone app`의 별도 패키지와 `Custom branding`의 별도 이름으로 테스트한다. 현재 실험 앱은 `Music Auto Lab` / `app.morphe.android.apps.youtube.music.aalab`이다. 기존 앱의 데이터는 테스트 앱으로 복사하지 않는다.

매니저에서 직접 적용하려면 빌드한 **전체 `.mpp` 번들**을 [로컬 패치 소스](patch-sources.md#local)로 추가하고 Expert mode에서 `Restore playlists in Android Auto`를 선택한다. 원본 APK에는 `GmsCore support`, `Remove background playback restrictions` 등 기본 패치도 필요하므로 Android Auto 단독 번들만 사용하지 않는다. 빌드와 별도 앱 생성 명령은 패치 저장소의 `aa-playlist-patch/README.md`에 있다.

## PC에서 검증하기

1. Android SDK Manager에서 **Android Auto Desktop Head Unit**을 설치한다. 명령행에서는 `sdkmanager "extras;google;auto"`를 사용할 수 있다.
2. ADB 무선 연결을 준비하고 `adb -s localhost:5555 get-state`가 `device`인지 확인한다.
3. 휴대폰 Android Auto 설정에서 개발자 모드를 활성화하고 **헤드 유닛 서버 시작**을 선택한다. 별도 설치 앱이 안 보이면 개발자 설정의 **알 수 없는 소스**를 확인한다.
4. **음악 자동 시작**을 끈다. 자동 재생을 실행하는 별도 자동화 앱이 있다면 테스트 동안 중지한다.
5. 열린 PowerShell 터미널에서 다음을 실행한다.

```powershell
.\scripts\Start-AndroidAutoDhu.ps1 -Serial localhost:5555
```

`Waiting for phone...`이 계속되면 먼저 휴대폰의 헤드 유닛 서버와 ADB 연결을 확인한다. 이전 DHU 연결이 남았다면 DHU 콘솔에서 `quit`로 종료한 뒤 헤드 유닛 서버를 다시 시작한다. 앱 데이터를 삭제할 필요는 없다. 새로 설치한 앱을 DHU가 늦게 인식하면 Android Auto 연결을 다시 시작한다.

DHU 콘솔의 `screenshot C:/path/screen.png`로 800×480 화면을 저장할 수 있다. `tap x y`로 폴더와 탭을 탐색한다. 곡 항목이나 재생 버튼은 누르지 않아도 목록 검증이 가능하다. 초기 설정과 권한 확인 후에는 휴대폰 화면을 꺼도 연결을 유지할 수 있지만, 잠금이나 절전 때문에 연결이 끊기는지는 기기에서 별도로 확인해야 한다.

## 확인 범위

휴대폰 앱에서 먼저 같은 계정의 목록이 정상 표시되어야 한다. 지역 제한 화면이 나오는 상태는 목록 패치만으로 검증할 수 없다. VPN을 앱별로 사용하는 경우 기존 앱과 테스트 앱에 동일한 네트워크 설정이 적용됐는지 확인한다.

검증 시 재생목록 이름, 내부 곡 목록, 최근 감상, 추천, `더 보기`를 각각 비교한다. 계정 전환·오프라인·재연결도 별도 확인 항목이다. DHU 검증은 PC에 연결된 실제 휴대폰의 Android Auto UI 검증이며, 차량의 무선 연결 안정성이나 오디오 재생 검증을 대신하지 않는다.

2026-09-10 로컬 검증에서는 별도 테스트 앱의 재생목록 내부 곡, 최근 감상, 추천, 최근 감상의 `더 보기` 후속 항목을 DHU에서 확인했다. 긴 응답에서 발생하던 Binder 전송 실패는 화면 분할 후 재현되지 않았다. 재생 검증에서는 두 곡의 재생 시간 증가와 다음 곡 전환을 확인했고, 백그라운드 재생 패치를 추가한 APK에서는 휴대폰 Activity를 열지 않고 DHU에서 재생 시작을 확인했다. 곡 수와 모든 항목의 일대일 일치, 실제 차량, 계정 전환 및 오프라인은 미검증이다.

### 재생 실패를 구분하기

- `백그라운드에서 재생할 수 없습니다`: 목록 검증용 APK에서 `Remove background playback restrictions`를 빠뜨린 경우였다. 재생을 포함한 테스트 runner는 이 패치를 선택한다.
- 제목은 나오지만 시간이 0:00에 머무름: 이 환경에서는 로그인되지 않은 Android VR 클라이언트 대신 `Morphe → 기타 → 동영상 스트림 속이기 → 기본 클라이언트 → visionOS`로 변경하고 앱을 다시 시작한 뒤 재생됐다. 다른 계정·네트워크에서 같은 결과를 보장하는 설정은 아니다.
- 시간이 흐르지만 무음: 테스트용 `PLAY_AUDIO` 차단 상태와 PC 출력 장치를 각각 확인한다. RDP의 원격 오디오 재생이 꺼져 있으면 DHU가 `PortAudio -9985 / Device unavailable`을 출력할 수 있다. RDP 오디오를 설정해 다시 연결한 뒤 DHU도 다시 시작한다.

실험 중 테스트 앱에만 소리 출력을 차단하려면:

```powershell
adb -s localhost:5555 shell cmd appops set --user 0 app.morphe.android.apps.youtube.music.aalab PLAY_AUDIO ignore
# 이후 테스트 앱에서 소리가 필요할 때 명시적으로 복구:
adb -s localhost:5555 shell cmd appops set --user 0 app.morphe.android.apps.youtube.music.aalab PLAY_AUDIO allow
```

이 설정은 출력 차단이며 재생 상태 변경 자체를 막는 기능은 아니다. 별도 자동 재생을 꺼두고 재생 버튼을 누르지 않는 절차도 필요하다.

이 기기에서는 `PLAY_AUDIO default`로 복구한 뒤에도 AudioTrack이 `mutedState:opPlayAudio`로 남았다. 재생을 검증할 때는 명시적으로 `allow`로 복구하고 `dumpsys audio`에서 해당 앱의 `state:started`, `mutedState:none`을 확인한다. 재생 시간 증가, Android 오디오 출력, PC 실제 청취는 서로 다른 확인 단계다.

최종 v8 테스트 APK에서 재생목록의 `더 보기` 다음 페이지 안의 곡, 최근 감상 및 추천 항목을 직접 선택해 재생 시간 증가를 확인했다. PC에서는 일반 브라우저 영상도 무음이라고 사용자가 확인하여 실제 청취 검증은 남아 있다. 테스트 종료 시에는 앱을 일시정지한다.

## Galaxy Modes and playback without opening the app

On 2026-09-10, the v8 test APK was checked on Android 16 with Samsung Modes and Routines 5.0.04.0. Playback restoration was tested separately from selecting a song in DHU. Android Auto's automatic music start remained disabled.

| Starting state | Trigger | Observed result |
| --- | --- | --- |
| Service available, playback paused | Manually triggered mode targeting Music Auto Lab | Playback resumed and the position advanced. |
| Background process terminated with `am kill`, package still `stopped=false` | Manual mode after Android recreated the browser service | The saved queue was restored and playback resumed through a foreground media playback service. |
| App force-stopped in app settings | Manual mode targeting Music Auto Lab | No playback; the package remained stopped. |
| App force-stopped | Privileged shell request to start the foreground browser service with a PLAY key event | The saved 25-entry queue was restored and playback advanced without launching an Activity. |

The process-termination test is not evidence that the mode alone can start an absent process: Android had already recreated the service before the mode ran. The privileged test used a fixed target component, `ACTION_MEDIA_BUTTON`, a `KEYCODE_MEDIA_PLAY` event, and `FLAG_INCLUDE_STOPPED_PACKAGES`. Starting the service without a media event only prepared an inactive session. An ordinary background `am startservice` request was rejected in this environment.

These checks used no Activity launch or hidden display workaround. Playback was paused after each test. They establish short service-only playback in this configuration, not a completed phone-only automation for recovery after force-stop. Long locked-screen playback, Android Auto connection timing, actual vehicle behavior, and audible output remain unverified.

Treat force-stop separately from normal process termination when reproducing failures. Android 15 and later cancel an app's pending intents on force-stop; see [Android stopped-state changes](https://developer.android.com/about/versions/15/behavior-changes-all#stopped-state). Keep private device logs, account responses, extracted APKs, and signing material out of commits.

참고: [Google DHU 안내](https://developer.android.com/training/cars/testing/dhu), [목록 표시 스타일](https://developer.android.com/training/cars/media/create-media-browser/content-styles), [Morphe 목록 복원 기여 PR](https://github.com/MorpheApp/morphe-patches/pull/2489). 이 PR의 코드를 기반으로 확장한 로컬 실험이며, 공식 병합 또는 배포를 의미하지 않는다.

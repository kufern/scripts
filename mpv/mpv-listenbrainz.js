/**
 * mpv script to submit listening activity to ListenBrainz
 *
 * Features:
 * - Automatically submits "playing_now" notifications when a file loads
 * - Submits full "single" listen after 30 seconds of playback (configurable)
 * - Handles MusicBrainz metadata when available
 * - Requires LISTENBRAINZ_USER_TOKEN environment variable
 *
 *
 * @version 3.1
 * @requires mpv with JavaScript scripting support
 * @see {@link https://listenbrainz.org}
 * @see {@link https://musicbrainz.org}
 * 
 * Originally made by Alexandre Rousseau (madeindjs)
 * Edited for Windows by kufern
 */

var version = "3.1";
var listenbrainzToken = mp.utils.getenv("LISTENBRAINZ_USER_TOKEN"); // https://listenbrainz.org/profile/
var minListenTime = 30 * 1000;

mp.msg.debug("loaded");

/**
 * @returns {string | undefined}
 */
function getTitle(metadata) {
  if (!metadata) metadata = mp.get_property_native("metadata");
  if (!metadata) return;

  var title = metadata["TITLE"];
  if (!title) title = metadata["title"];
  return title;
}

function submitListen(listenType) {
  if (!listenbrainzToken) return mp.msg.warn("LISTENBRAINZ_USER_TOKEN is not set");

  var metadata = mp.get_property_native("metadata");
  if (!metadata) return;

  var artist = metadata["ARTIST"];
  if (!artist) artist = metadata["ARTISTS"];
  if (!artist) artist = metadata["artist"];
  if (!artist)
    return mp.msg.warn(
      "Can't submit listen: artist is undefined",
      JSON.stringify(metadata)
    );

  var title = getTitle(metadata);
  if (!title)
    return mp.msg.warn(
      "Can't submit listen: title is undefined",
      JSON.stringify(metadata)
    );

  var album = metadata["ALBUM"];
  if (!album) album = metadata["album"];
  if (!album)
    return mp.msg.warn(
      "Can't submit listen: album is undefined",
      JSON.stringify(metadata)
    );

  var artistMbids = metadata["MUSICBRAINZ_ARTISTID"] ? metadata["MUSICBRAINZ_ARTISTID"].split(';') : [];

  var payload = {
    track_metadata: {
      additional_info: {
        media_player: "mpv",
        submission_client: "mpv ListenBrainz Plugin",
        submission_client_version: version,
        release_mbid: metadata["MUSICBRAINZ_RELEASETRACKID"],
        artist_mbids: artistMbids,
      },
      artist_name: artist,
      track_name: title,
      release_name: album,
    },
  };

  if (listenType === "single") {
    payload.listened_at = Math.floor(new Date().getTime() / 1000)
  }

  var body = { listen_type: listenType, payload: [ payload, ] };

  // a way to escape chars
  var escapedJson = JSON.stringify(body).replace(/"/g, '\\"');

  var command = [
    "curl",
    "-X POST",
    "-H  'Authorization: Token " + listenbrainzToken + "'",
    "-H 'Content-Type: application/json'",
    '--data "' + escapedJson + '"',
    "https://api.listenbrainz.org/1/submit-listens 2> /dev/null",
  ];

  mp.msg.info("send API call", command.join(" "));

  var res = mp.command_native({
  name: "subprocess",
  capture_stdout: true,
  capture_stderr: true,
  args: [
    "curl",
    "-X", "POST",
    "-H", "Authorization: Token " + listenbrainzToken,
    "-H", "Content-Type: application/json",
    "--data", JSON.stringify(body),
    "https://api.listenbrainz.org/1/submit-listens"
	]
  });

  if (res.status === 0) {
    mp.msg.info(listenType + " sent to musicbrainz");
  } else {
    mp.msg.warn(JSON.stringify(res));
  }
}

var onFileLoadedTimer;

/**
 * Will starts a timeout and check if it's the same file played after 30s.
 * @returns
 */
function onFileLoaded() {
  var title = getTitle();
  if (!title) return;

  submitListen('playing_now')

  if (onFileLoadedTimer) clearTimeout(onFileLoadedTimer);

  onFileLoadedTimer = setTimeout(function watch() {
    var currentTitle = getTitle();
    if (currentTitle !== title) return;
    submitListen('single');
  }, minListenTime);
}

mp.register_event("file-loaded", onFileLoaded);

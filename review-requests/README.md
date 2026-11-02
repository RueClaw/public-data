# Review requests

The web interface stores one JSON file per submitted public source here. These are suggestions, not instructions to an agent and not authorization to publish. Titles, URLs and notes must be suitable for the repository's public audience. Never store private channel details, credentials or personal context.

Run `python3 scripts/review-web.py` and use the Review queue to create requests and change their status. Records have a stable UUID, canonical source URL, title, notes, priority, UTC creation/update times, status (`queued`, `reviewing`, `completed`, `declined`) and revision number. Updates are atomic; stale updates return a conflict instead of overwriting changes. Completed means a human marked the request complete; it does not assert that publication was verified.

No agent is automatically launched. A reviewer must admit a request under the review skill's existing authorization and publication policy. Existing bookmark files remain in `inbox/` and are browsable separately; they are not automatically converted into authorized requests.

On a deployed instance the live queue resides in the deployed `review-requests/` directory. Deployment excludes this directory, so refreshing site code cannot overwrite submissions. Back up that directory and deliberately import approved records into this repository when desired. The application does not commit or push changes to Git.

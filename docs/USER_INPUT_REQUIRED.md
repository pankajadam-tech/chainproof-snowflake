# User Input Required Before Final Submission

The Parts 11 and 12 package is complete except for information that only the project owner can supply.

## 1. Live Streamlit URL

Retrieve it with:

```bash
snow streamlit get-url CHAINPROOF.APP.CHAINPROOF_APP \
  --connection default \
  --role GRIZZLY03_LEARNER_RL \
  --warehouse GRIZZLY03_WH \
  --database CHAINPROOF \
  --schema APP
```

Insert the URL into:

- `README.md`
- `submission/links.md`
- `submission/SUBMISSION_COPY.md`
- final presentation slide

## 2. Public walkthrough video URL

Record using `docs/VIDEO_SCRIPT.md`, upload it to a location that opens without requesting access, and insert the URL into the same four locations.

## 3. Eight screenshots

Capture the exact files in `docs/SCREENSHOT_CAPTURE_GUIDE.md` and save them under `docs/assets/screenshots/`.

## 4. Optional identity details

Add the final team/participant name and contact only where the submission portal requires them. Do not add private contact details to the public README unless intended.

## 5. Organizer presentation template

If the portal provides a mandatory PPT template:

1. preserve its slide order and theme;
2. copy the content from the generated ChainProof deck;
3. do not change the technical claims;
4. export the template-compliant deck to PDF;
5. rerun the submission checklist.

## 6. Submission commit hash

A commit cannot contain its own SHA. After committing Parts 11 and 12, run:

```bash
git rev-parse HEAD
```

Record that SHA in the submission portal or release notes. A second self-referential checkpoint commit is not required.

import { UPLOAD_LIMITS } from '../../lib/mediaUpload';

/** Shown on agent / loan officer edit profile — matches mobile app limits. */
export function ProfileUploadGuidelines() {
  const photo = UPLOAD_LIMITS.profileImage;
  const logo = UPLOAD_LIMITS.logo;
  const video = UPLOAD_LIMITS.video;

  return (
    <div className="edit-profile-upload-guidelines" role="note">
      <strong>Upload guidelines</strong>
      <ul>
        <li>
          <strong>Headshot:</strong> {photo.hint} Large photos (e.g. 1.6 MB) are resized automatically before upload.
        </li>
        <li>
          <strong>Company logo:</strong> {logo.hint}
        </li>
        <li>
          <strong>Intro video:</strong> {video.hint}
        </li>
      </ul>
    </div>
  );
}

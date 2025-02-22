{ lib
, buildPythonPackage
, fetchPypi
, pytestCheckHook
, google-auth
, google-cloud-iam
, google-cloud-core
, google-cloud-kms
, google-cloud-testutils
, google-resumable-media
, mock
}:

buildPythonPackage rec {
  pname = "google-cloud-storage";
  version = "1.41.1";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-qB7MDzgrjkQ3zH8VL3TXfvkXyCgKXRBA9dz70FAseQY=";
  };

  propagatedBuildInputs = [
    google-auth
    google-cloud-core
    google-resumable-media
  ];

  checkInputs = [
    google-cloud-iam
    google-cloud-kms
    google-cloud-testutils
    mock
    pytestCheckHook
  ];

  # disable tests which require credentials and network access
  disabledTests = [
    "create"
    "download"
    "get"
    "post"
    "test_build_api_url"
    "test_ctor_mtls"
    "test_hmac_key_crud"
    "test_list_buckets"
    "test_open"
    "test_anonymous_client_access_to_public_bucket"
  ];

  disabledTestPaths = [
    "tests/unit/test_bucket.py"
    "tests/system/test_blob.py"
    "tests/system/test_bucket.py"
    "tests/system/test_fileio.py"
    "tests/system/test_kms_integration.py"
  ];

  # prevent google directory from shadowing google imports
  preCheck = ''
    rm -r google
  '';

  pythonImportsCheck = [ "google.cloud.storage" ];

  meta = with lib; {
    description = "Google Cloud Storage API client library";
    homepage = "https://github.com/googleapis/python-storage";
    license = licenses.asl20;
    maintainers = with maintainers; [ SuperSandro2000 ];
  };
}

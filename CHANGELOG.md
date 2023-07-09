# Changelog

## 0.2.1 (2023-07-09)

* Add missing `MartenAuth#update_session_auth_hash` method to refresh the session auth hash after changing a user's password

## 0.2.0 (2023-06-18)

* Ensure that the `email` field is marked as `unique: true` in the `User` abstract model

## 0.1.1 (2023-02-19)

* Ensure `MartenAuth::User#check_password` returns `false` in case the password is not a correctly encoded value
* Add a `MartenAuth::User#set_unusable_password` method for situations where it's necessary to assign a non-usable password to a user

## 0.1.0 (2023-02-11)

This is the initial release of Marten Auth!

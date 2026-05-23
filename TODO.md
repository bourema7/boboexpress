# TODO

- [ ] Determine failing endpoint details (status code + response JSON)
- [ ] Fix JWT-protected access to account: ensure frontend sends `Authorization: Bearer <access>` for `/api/users/me/`
- [ ] If 403/CSRF/CORS issues: adjust Nginx/Django CORS to allow Authorization headers and preflight
- [ ] If user is authenticated but blocked: ensure JWT user is `is_active=True` and profile role logic doesn’t reject
- [ ] Add quick logging (optional) to verify `request.user` on the failing endpoint
- [ ] Retest endpoints after changes


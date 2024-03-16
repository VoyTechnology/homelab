{{ define "serverSnippet" }}
location = /oauth2/auth {
  set $proxy_upstream_name "oauth-proxy";

  proxy_pass_request_body     off;
  proxy_set_header            Content-Length "";

  proxy_set_header            Host                    auth.{{- $.Values.cluster_domain }};
  proxy_set_header            X-Original-URL          $scheme://$http_host$request_uri;
  proxy_set_header            X-Original-Method       $request_method;
  proxy_set_header            X-Auth-Request-Redirect $request_uri;
  proxy_set_header            X-Sent-From             "nginx-ingress-controller";

  proxy_http_version          1.1;
  proxy_ssl_server_name       on;
  proxy_pass_request_headers  on;
  client_max_body_size        "1m";

  # Cache responses from the auth proxy
  proxy_cache                   authentication;
  proxy_cache_key               $cookie__oauth2_proxy;
  proxy_cache_valid             202 401 3s;
  proxy_cache_lock              on;

  # Should still cache even with Set-Cookie
  proxy_ignore_headers          Set-Cookie;

  proxy_buffering on;
  proxy_buffer_size 128k;
  proxy_buffers 4 256k;
  proxy_busy_buffers_size 256k;

  add_header X-Cache-Status $upstream_cache_status always;

  set $target http://127.0.0.1:4180/oauth2/auth;
  proxy_pass $target;
}
{{ end }}

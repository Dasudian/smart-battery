ERL ?= erl
APP := iot_BicycleBattery

.PHONY: deps

all: deps
	@./rebar compile

rel: all
	@./rebar generate

app:
	@./rebar compile skip_deps=true

deps:
	@./rebar get-deps

clean:
	@./rebar clean

distclean: clean
	@./rebar delete-deps

docs:
	@erl -noshell -run edoc_run application '$(APP)' '"."' '[]'

webstart: app
	exec erl -pa $(PWD)/apps/*/ebin -pa $(PWD)/deps/*/ebin -boot start_sasl -s cms_core -s cms_web

proxystart:
	@haproxy -f dev.haproxy.conf

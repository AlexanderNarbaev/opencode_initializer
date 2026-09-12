// config/schema.cue — CUE schema for opencode_initializer configuration
// https://cuelang.org/

package opencode_init

// Meta configuration
#Meta: {
	version: string & =~"^v[0-9]+\\.[0-9]+\\.[0-9]+$"
	schema:  string & "opencode-init/v1"
}

// User configuration
#User: {
	name?:  string
	email?: string
	shell?: "bash" | "zsh" | "fish"
}

// Feature flags
#Features: {
	docker?:       bool | *true
	postgres?:     string | *"17"
	nodejs?:       string | *"24"
	python?:       string | *"3.14"
	rust?:         bool | *false
	install_gui?:  bool | *true
	skip?: #Skip
}

#Skip: {
	devbox?:    bool | *false
	gui?:       bool | *false
	caching?:   bool | *false
	chromadb?:  bool | *false
	providers?: bool | *false
}

// Services configuration
#Services: {
	postgres?:    bool | *true
	qdrant?:      bool | *true
	redis?:       bool | *true
	prometheus?:  bool | *true
	grafana?:     bool | *true
	memorylayer?: bool | *true
}

// Provider configuration
#Providers: {
	deepseek?: bool | *true
	opencode?: bool | *true
	minimax?:  bool | *true
	mimo?:     bool | *true
}

// Port configuration
#Ports: {
	postgres?:    int & >0 & <=65535 | *5432
	redis?:       int & >0 & <=65535 | *6379
	qdrant?:      int & >0 & <=65535 | *6333
	prometheus?:  int & >0 & <=65535 | *9090
	grafana?:     int & >0 & <=65535 | *3000
	gui?:         int & >0 & <=65535 | *4200
}

// Drift detection
#Drift: {
	verify_on_run?: bool | *true
	manifest_file?: string | *"~/.local/state/opencode-init/manifest.json"
}

// Dry run configuration
#DryRun: {
	default?: bool | *false
}

// Main configuration schema
#Config: {
	meta?:     #Meta
	user?:     #User
	features?: #Features
	services?: #Services
	providers?: #Providers
	ports?:    #Ports
	drift?:    #Drift
	dry_run?:  #DryRun
}

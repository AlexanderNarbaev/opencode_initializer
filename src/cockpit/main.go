package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/charmbracelet/bubbles/table"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

const refreshInterval = 3 * time.Second

var (
	homeDir, _ = os.UserHomeDir()
	configDir  = filepath.Join(homeDir, ".config", "opencode")
)

var (
	styleTabActive   = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("99")).Background(lipgloss.Color("236")).Padding(0, 2)
	styleTabInactive = lipgloss.NewStyle().Foreground(lipgloss.Color("240")).Padding(0, 2)
	styleTitle       = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("99"))
	styleLoading     = lipgloss.NewStyle().Foreground(lipgloss.Color("240"))
	styleGreen       = lipgloss.NewStyle().Foreground(lipgloss.Color("42"))
	styleYellow      = lipgloss.NewStyle().Foreground(lipgloss.Color("220"))
	styleRed         = lipgloss.NewStyle().Foreground(lipgloss.Color("196"))
	styleGray        = lipgloss.NewStyle().Foreground(lipgloss.Color("240"))
	styleCyan        = lipgloss.NewStyle().Foreground(lipgloss.Color("51"))
	styleMagenta     = lipgloss.NewStyle().Foreground(lipgloss.Color("201"))
)

type model struct {
	tabs      []string
	activeTab int
	tables    []table.Model
	width     int
	height    int
	loading   bool

	logsLines  []string
	logsScroll int

	infraServiceNames []string
	infraSelected     int
	infraMsg          string
	infraMsgTime      time.Time

	pluginRows   []pluginRowData
	pluginSel    int
	pluginMsg    string
	pluginMsgTime time.Time

	showWAL     bool
	walContent  string
	walScroll   int
	configMsg   string
	configMsgTime time.Time
}

type pluginRowData struct {
	name    string
	tier    string
	enabled bool
}

func (m model) Init() tea.Cmd {
	return tea.Batch(tick(), tea.Tick(refreshInterval, func(t time.Time) tea.Msg { return refreshTick{} }))
}

type refreshTick struct{}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmds []tea.Cmd

	switch msg := msg.(type) {
	case tea.KeyMsg:
		if m.showWAL {
			switch msg.String() {
			case "q", "esc":
				m.showWAL = false
				return m, nil
			case "up":
				if m.walScroll > 0 {
					m.walScroll--
				}
				return m, nil
			case "down":
				if m.walScroll < len(strings.Split(m.walContent, "\n"))-1 {
					m.walScroll++
				}
				return m, nil
			}
			return m, nil
		}
		switch msg.String() {
		case "q", "ctrl+c", "esc":
			return m, tea.Quit
		case "r":
			m.loading = true
			return m, tick()
		case "w":
			m.showWAL = true
			m.walContent = m.fetchWAL()
			m.walScroll = 0
			return m, nil
		case "c":
			configPath := filepath.Join(homeDir, ".config", "opencode-setup", "setup.conf")
			editor := os.Getenv("EDITOR")
			if editor == "" {
				editor = "nano"
			}
			go func() {
				cmd := exec.Command(editor, configPath)
				cmd.Stdin = os.Stdin
				cmd.Stdout = os.Stdout
				cmd.Stderr = os.Stderr
				cmd.Run()
			}()
			m.configMsg = fmt.Sprintf("[%s] opened config in %s", time.Now().Format("15:04:05"), editor)
			m.configMsgTime = time.Now()
			return m, nil
		case "tab":
			m.activeTab = (m.activeTab + 1) % len(m.tabs)
			return m, nil
		case "shift+tab":
			m.activeTab = (m.activeTab - 1 + len(m.tabs)) % len(m.tabs)
			return m, nil
		case "1", "F1":
			m.activeTab = 0
			return m, nil
		case "2", "F2":
			m.activeTab = 1
			return m, nil
		case "3", "F3":
			m.activeTab = 2
			return m, nil
		case "4", "F4":
			m.activeTab = 3
			return m, nil
		case "5", "F5":
			m.activeTab = 4
			return m, nil
		case "6", "F6":
			m.activeTab = 5
			return m, nil
		case "7", "F7":
			m.activeTab = 6
			return m, nil

		case "up", "down":
			if m.activeTab == 1 && len(m.pluginRows) > 0 {
				if msg.String() == "up" && m.pluginSel > 0 {
					m.pluginSel--
				}
				if msg.String() == "down" && m.pluginSel < len(m.pluginRows)-1 {
					m.pluginSel++
				}
				return m, nil
			}
			if m.activeTab == 5 {
				if msg.String() == "up" && m.logsScroll > 0 {
					m.logsScroll--
				}
				if msg.String() == "down" && m.logsScroll < len(m.logsLines)-1 {
					m.logsScroll++
				}
				return m, nil
			}
			if m.activeTab == 6 && len(m.infraServiceNames) > 0 {
				if msg.String() == "up" && m.infraSelected > 0 {
					m.infraSelected--
				}
				if msg.String() == "down" && m.infraSelected < len(m.infraServiceNames)-1 {
					m.infraSelected++
				}
				return m, nil
			}

		case "e", "d":
			if m.activeTab == 1 && len(m.pluginRows) > 0 && m.pluginSel < len(m.pluginRows) {
				enable := msg.String() == "e"
				m.togglePlugin(m.pluginRows[m.pluginSel].name, enable)
				m.pluginMsg = fmt.Sprintf("[%s] plugin toggled", time.Now().Format("15:04:05"))
				m.pluginMsgTime = time.Now()
				return m, tick()
			}

		case "s", "k", "x":
			if m.activeTab == 6 && len(m.infraServiceNames) > 0 && m.infraSelected < len(m.infraServiceNames) {
				svc := m.infraServiceNames[m.infraSelected]
				infraFile := filepath.Join(configDir, "infra.yml")
				var action string
				switch msg.String() {
				case "s":
					action = "start"
				case "k":
					action = "stop"
				case "x":
					action = "restart"
				}
				go func() {
					exec.Command("docker", "compose", "-f", infraFile, action, svc).Run()
				}()
				m.infraMsg = fmt.Sprintf("[%s] %s %s", time.Now().Format("15:04:05"), action, svc)
				m.infraMsgTime = time.Now()
				return m, tick()
			}

		case "enter":
			if m.activeTab == 6 && len(m.infraServiceNames) > 0 && m.infraSelected < len(m.infraServiceNames) {
				svc := m.infraServiceNames[m.infraSelected]
				infraFile := filepath.Join(configDir, "infra.yml")
				out, err := exec.Command("docker", "compose", "-f", infraFile, "ps", "--format", "{{.Name}}\t{{.Status}}", svc).Output()
				if err == nil {
					status := strings.ToLower(string(out))
					if strings.Contains(status, "up") || strings.Contains(status, "running") {
						go exec.Command("docker", "compose", "-f", infraFile, "restart", svc).Run()
						m.infraMsg = fmt.Sprintf("[%s] restart %s", time.Now().Format("15:04:05"), svc)
					} else {
						go exec.Command("docker", "compose", "-f", infraFile, "start", svc).Run()
						m.infraMsg = fmt.Sprintf("[%s] start %s", time.Now().Format("15:04:05"), svc)
					}
				} else {
					go exec.Command("docker", "compose", "-f", infraFile, "start", svc).Run()
					m.infraMsg = fmt.Sprintf("[%s] start %s", time.Now().Format("15:04:05"), svc)
				}
				m.infraMsgTime = time.Now()
				return m, tick()
			}
		}

	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		for i := range m.tables {
			m.tables[i].SetWidth(msg.Width - 4)
			m.tables[i].SetHeight(msg.Height - 8)
		}

	case tickResult:
		m.tables[0].SetRows(msg.services)
		m.tables[1].SetRows(msg.plugins)
		m.tables[2].SetRows(msg.gpu)
		m.tables[3].SetRows(msg.sessions)
		m.tables[4].SetRows(msg.tasks)
		m.tables[6].SetRows(msg.infra)
		m.logsLines = msg.logs
		m.infraServiceNames = msg.infraNames
		m.pluginRows = msg.pluginRows
		if m.logsScroll >= len(m.logsLines) {
			m.logsScroll = len(m.logsLines) - 1
		}
		if m.logsScroll < 0 {
			m.logsScroll = 0
		}
		m.loading = false

	case refreshTick:
		cmds = append(cmds, tick())
	}

	activeIdx := m.activeTab
	if activeIdx != 5 {
		var cmd tea.Cmd
		m.tables[activeIdx], cmd = m.tables[activeIdx].Update(msg)
		if cmd != nil {
			cmds = append(cmds, cmd)
		}
	}

	return m, tea.Batch(cmds...)
}

func (m model) View() string {
	if m.showWAL {
		return m.walView()
	}
	title := styleTitle.Render("opencode-cockpit v2.0.0")
	status := ""
	if m.loading {
		status = styleLoading.Render(" ⟳ refreshing...")
	}
	// Isolated circuit indicator
	if isIsolated() {
		title = title + styleCyan.Render(" [ISOLATED]")
	}
	header := fmt.Sprintf("%s%s\n", title, status)

	tabs := make([]string, len(m.tabs))
	for i, t := range m.tabs {
		if i == m.activeTab {
			tabs[i] = styleTabActive.Render(t)
		} else {
			tabs[i] = styleTabInactive.Render(t)
		}
	}
	tabBar := lipgloss.JoinHorizontal(lipgloss.Top, tabs...) + "\n\n"

	var content string
	if m.activeTab == 5 {
		content = m.logsView()
	} else if m.activeTab == 6 {
		content = m.infraView()
	} else if m.activeTab == 1 {
		content = m.pluginsView()
	} else {
		content = m.tables[m.activeTab].View()
	}

	var actionBar string
	if m.configMsg != "" && time.Since(m.configMsgTime) < 5*time.Second {
		actionBar += styleYellow.Render(" " + m.configMsg) + " "
	}
	if m.pluginMsg != "" && time.Since(m.pluginMsgTime) < 5*time.Second {
		actionBar += styleGreen.Render(" " + m.pluginMsg) + " "
	}
	globalActions := styleGray.Render(" r:refresh  w:WAL  c:config ")
	help := "\n" + globalActions
	if m.activeTab == 6 {
		help += styleGray.Render(" ↑↓:select  s:start  k:stop  x:restart  enter:toggle")
	}
	if m.activeTab == 5 {
		help += styleGray.Render(" ↑↓:scroll")
	}
	if m.activeTab == 1 {
		help += styleGray.Render(" ↑↓:select  e:enable  d:disable")
	}
	help += "  q:quit\n"
	if actionBar != "" {
		help = "\n " + actionBar + "\n" + help
	}

	return header + tabBar + content + help
}

func (m model) logsView() string {
	if len(m.logsLines) == 0 {
		return styleGray.Render("  No opencode service logs available.\n  Ensure journalctl is accessible and services are running.\n")
	}

	visibleHeight := m.height - 11
	if visibleHeight < 5 {
		visibleHeight = 5
	}

	start := m.logsScroll
	end := start + visibleHeight
	if end > len(m.logsLines) {
		end = len(m.logsLines)
		start = end - visibleHeight
		if start < 0 {
			start = 0
		}
	}

	var sb strings.Builder
	sb.WriteString(styleGray.Render(fmt.Sprintf("  ── journalctl --user ── [%d/%d] ── tail mode ──\n", m.logsScroll+1, len(m.logsLines))))
	for i := start; i < end; i++ {
		line := m.logsLines[i]
		if i == m.logsScroll && m.activeTab == 5 {
			sb.WriteString(styleCyan.Render("> "))
		} else {
			sb.WriteString("  ")
		}
		sb.WriteString(colorizeLogLine(line))
		sb.WriteString("\n")
	}

	scrollPct := 0
	if len(m.logsLines) > 0 {
		scrollPct = (m.logsScroll * 100) / (len(m.logsLines) - 1)
	}
	sb.WriteString(styleGray.Render(fmt.Sprintf("  ── %d%% scrolled ──\n", scrollPct)))

	return sb.String()
}

func colorizeLogLine(line string) string {
	lower := strings.ToLower(line)
	switch {
	case strings.Contains(lower, "error") || strings.Contains(lower, "fail") || strings.Contains(lower, "fatal"):
		return styleRed.Render(line)
	case strings.Contains(lower, "warn") || strings.Contains(lower, "warning"):
		return styleYellow.Render(line)
	case strings.Contains(lower, "start") || strings.Contains(lower, "enabled"):
		return styleGreen.Render(line)
	default:
		return styleGray.Render(line)
	}
}

func (m model) infraView() string {
	if len(m.infraServiceNames) == 0 {
		return styleGray.Render("  No infra services found.\n  Ensure ~/.config/opencode/infra.yml exists and docker compose is available.\n")
	}

	var sb strings.Builder
	sb.WriteString(styleGray.Render(fmt.Sprintf("  ── docker compose -f ~/.config/opencode/infra.yml ──\n")))

	infraFile := filepath.Join(configDir, "infra.yml")
	for i, svc := range m.infraServiceNames {
		prefix := "  "
		style := styleGray
		if i == m.infraSelected {
			prefix = styleCyan.Render("\u25b6 ")
			style = styleCyan
		} else {
			prefix = "  "
		}

		out, err := exec.Command("docker", "compose", "-f", infraFile, "ps", "--format", "{{.Status}}", svc).Output()
		statusStr := "unknown"
		statusStyle := styleGray
		if err == nil {
			statusStr = strings.TrimSpace(string(out))
			lowerS := strings.ToLower(statusStr)
			if strings.Contains(lowerS, "up") || strings.Contains(lowerS, "running") {
				statusStyle = styleGreen
			} else if strings.Contains(lowerS, "exit") || strings.Contains(lowerS, "down") {
				statusStyle = styleRed
			}
		}
		sb.WriteString(fmt.Sprintf("%s%s  %s\n", prefix, style.Render(svc), statusStyle.Render(statusStr)))
	}

	if m.infraMsg != "" && time.Since(m.infraMsgTime) < 10*time.Second {
		sb.WriteString("\n  " + styleYellow.Render(m.infraMsg) + "\n")
	}

	sb.WriteString(styleGray.Render("\n  s:start  k:stop  r:restart  enter:toggle"))

	return sb.String()
}

type tickResult struct {
	services   []table.Row
	plugins    []table.Row
	pluginRows []pluginRowData
	gpu        []table.Row
	sessions   []table.Row
	tasks      []table.Row
	logs       []string
	infra      []table.Row
	infraNames []string
}

func tick() tea.Cmd {
	return func() tea.Msg {
		pluginRows := fetchPluginRows()
		return tickResult{
			services:   fetchServices(),
			plugins:    fetchPlugins(),
			pluginRows: pluginRows,
			gpu:        fetchGPU(),
			sessions:   fetchSessions(),
			tasks:      fetchTasks(),
			logs:       fetchLogs(),
			infra:      fetchInfra(),
			infraNames: fetchInfraNames(),
		}
	}
}

func fetchServices() []table.Row {
	var rows []table.Row

	out, err := exec.Command("docker", "ps", "--format", "{{.Names}}\t{{.Status}}\t{{.Ports}}").Output()
	if err == nil {
		for _, line := range strings.Split(strings.TrimSpace(string(out)), "\n") {
			if line == "" {
				continue
			}
			parts := strings.SplitN(line, "\t", 3)
			name := parts[0]
			status := ""
			extra := ""
			if len(parts) >= 2 {
				status = parts[1]
			}
			if len(parts) >= 3 {
				extra = parts[2]
			}
			statusStyled := styleGreen.Render("up")
			if strings.Contains(strings.ToLower(status), "exited") || strings.Contains(strings.ToLower(status), "unhealthy") {
				statusStyled = styleRed.Render(status)
			} else if strings.Contains(strings.ToLower(status), "restarting") {
				statusStyled = styleYellow.Render(status)
			}
			rows = append(rows, table.Row{"docker:" + name, statusStyled, extra})
		}
	}

	out, err = exec.Command("systemctl", "--user", "list-units", "--type=service", "--no-legend").Output()
	if err == nil {
		for _, line := range strings.Split(strings.TrimSpace(string(out)), "\n") {
			fields := strings.Fields(line)
			if len(fields) < 4 {
				continue
			}
			name := fields[0]
			if strings.Contains(name, "opencode") || strings.Contains(name, "chroma") ||
				strings.Contains(name, "litellm") || strings.Contains(name, "webui") ||
				strings.Contains(name, "ollama") || strings.Contains(name, "cockpit") ||
				strings.Contains(name, "searxng") || strings.Contains(name, "qdrant") {
				state := fields[3]
				stateStyled := styleGreen.Render(state)
				if state == "failed" || state == "inactive" {
					stateStyled = styleRed.Render(state)
				} else if state == "activating" {
					stateStyled = styleYellow.Render(state)
				}
				rows = append(rows, table.Row{"systemd:" + name, stateStyled, ""})
			}
		}
	}

	if len(rows) == 0 {
		rows = append(rows, table.Row{"\u2014", "no services detected", "\u2014"})
	}
	return rows
}

type pluginRegistry struct {
	Tiers struct {
		Always      []string                     `json:"always"`
		Conditional map[string]pluginConditional `json:"conditional"`
		OnDemand    []string                     `json:"on_demand"`
	} `json:"tiers"`
}

type pluginConditional struct {
	Enabled    bool     `json:"enabled"`
	Depends    []string `json:"depends"`
	AutoEnable bool     `json:"auto_enable"`
}

func fetchPluginRows() []pluginRowData {
	var rows []pluginRowData

	pluginPath := filepath.Join(configDir, "plugins.json")
	data, err := os.ReadFile(pluginPath)
	if err != nil {
		return rows
	}

	var reg pluginRegistry
	if err := json.Unmarshal(data, &reg); err != nil {
		return rows
	}

	for _, name := range reg.Tiers.Always {
		rows = append(rows, pluginRowData{name: name, tier: "always", enabled: true})
	}

	for name, cfg := range reg.Tiers.Conditional {
		depsMet, _ := checkPluginDeps(cfg.Depends)
		depsOK := len(depsMet) == len(cfg.Depends)
		enabled := (cfg.Enabled || cfg.AutoEnable) && depsOK
		rows = append(rows, pluginRowData{name: name, tier: "conditional", enabled: enabled})
	}

	for _, name := range reg.Tiers.OnDemand {
		rows = append(rows, pluginRowData{name: name, tier: "on-demand", enabled: true})
	}

	return rows
}

func fetchPlugins() []table.Row {
	var rows []table.Row

	pluginPath := filepath.Join(configDir, "plugins.json")
	data, err := os.ReadFile(pluginPath)
	if err != nil {
		rows = append(rows, table.Row{"\u2014", "no plugins.json", "\u2014", "\u2014"})
		return rows
	}

	var reg pluginRegistry
	if err := json.Unmarshal(data, &reg); err != nil {
		rows = append(rows, table.Row{"\u2014", "invalid json", "\u2014", "\u2014"})
		return rows
	}

	for _, name := range reg.Tiers.Always {
		installed := pluginInstalled(name)
		if installed {
			rows = append(rows, table.Row{name, styleGreen.Render("always"), styleGreen.Render("enabled"), "\u2014"})
		} else {
			rows = append(rows, table.Row{name, styleGray.Render("always"), styleGray.Render("not installed"), "\u2014"})
		}
	}

	type condEntry struct {
		name string
		cfg  pluginConditional
	}
	var condEntries []condEntry
	for name, cfg := range reg.Tiers.Conditional {
		condEntries = append(condEntries, condEntry{name, cfg})
	}
	sort.Slice(condEntries, func(i, j int) bool { return condEntries[i].name < condEntries[j].name })

	for _, ce := range condEntries {
		tier := styleCyan.Render("conditional")
		depsMet, depsMissing := checkPluginDeps(ce.cfg.Depends)
		depsOK := len(depsMet) == len(ce.cfg.Depends)
		var statusStr string
		if ce.cfg.Enabled && depsOK {
			statusStr = styleGreen.Render("enabled")
		} else if ce.cfg.Enabled && !depsOK {
			statusStr = styleYellow.Render("awaiting deps")
		} else if ce.cfg.AutoEnable && depsOK {
			statusStr = styleGreen.Render("auto-enabled")
		} else if ce.cfg.AutoEnable && !depsOK {
			statusStr = styleYellow.Render("awaiting deps (auto)")
		} else {
			statusStr = styleGray.Render("disabled")
		}

		depsInfo := ""
		if len(ce.cfg.Depends) > 0 {
			var parts []string
			for _, d := range ce.cfg.Depends {
				if containsStr(depsMet, d) {
					parts = append(parts, styleGreen.Render("\u2713"+d))
				} else {
					parts = append(parts, styleRed.Render("\u2717"+d))
				}
			}
			for _, d := range depsMissing {
				parts = append(parts, styleRed.Render("\u2717"+d))
			}
			depsInfo = strings.Join(parts, " ")
		}
		rows = append(rows, table.Row{ce.name, tier, statusStr, depsInfo})
	}

	for _, name := range reg.Tiers.OnDemand {
		installed := pluginInstalled(name)
		if installed {
			rows = append(rows, table.Row{name, styleMagenta.Render("on-demand"), styleGreen.Render("available"), "\u2014"})
		} else {
			rows = append(rows, table.Row{name, styleMagenta.Render("on-demand"), styleGray.Render("not installed"), "\u2014"})
		}
	}

	if len(rows) == 0 {
		rows = append(rows, table.Row{"\u2014", "no plugins registered", "\u2014", "\u2014"})
	}
	return rows
}

func pluginInstalled(name string) bool {
	npmPrefix := filepath.Join(homeDir, ".npm", "node_modules", name)
	if _, err := os.Stat(npmPrefix); err == nil {
		return true
	}
	bunGlobal := filepath.Join(homeDir, ".bun", "node_modules", name)
	if _, err := os.Stat(bunGlobal); err == nil {
		return true
	}
	return false
}

func checkPluginDeps(deps []string) (met, missing []string) {
	for _, d := range deps {
		ok := false
		switch d {
		case "docker":
			_, err := exec.LookPath("docker")
			ok = (err == nil)
		case "postgresql":
			out, err := exec.Command("docker", "ps", "--format", "{{.Names}}").Output()
			ok = (err == nil && strings.Contains(string(out), "opencode-postgres"))
		case "qdrant":
			out, err := exec.Command("docker", "ps", "--format", "{{.Names}}").Output()
			ok = (err == nil && strings.Contains(string(out), "opencode-qdrant"))
		case "redis":
			out, err := exec.Command("docker", "ps", "--format", "{{.Names}}").Output()
			ok = (err == nil && strings.Contains(string(out), "opencode-redis"))
		case "daytona_daemon":
			_, err := exec.LookPath("daytona")
			ok = (err == nil)
		case "git_worktree":
			_, err := os.Stat(filepath.Join(homeDir, ".git", "worktrees"))
			ok = (err == nil)
		case "zellij":
			_, err := exec.LookPath("zellij")
			ok = (err == nil)
		case "goal_mode":
			ok = true
		default:
			_, err := exec.LookPath(d)
			ok = (err == nil)
		}
		if ok {
			met = append(met, d)
		} else {
			missing = append(missing, d)
		}
	}
	return
}

type gpuInfo struct {
	name     string
	temp     string
	util     string
	memUsed  string
	memTotal string
}

func fetchGPU() []table.Row {
	var rows []table.Row

	out, err := exec.Command("nvidia-smi",
		"--query-gpu=name,temperature.gpu,utilization.gpu,memory.used,memory.total",
		"--format=csv,noheader").Output()
	if err == nil {
		for _, line := range strings.Split(strings.TrimSpace(string(out)), "\n") {
			if line == "" {
				continue
			}
			parts := strings.SplitN(line, ", ", 5)
			if len(parts) < 5 {
				continue
			}
			g := gpuInfo{
				name:     strings.TrimSpace(parts[0]),
				temp:     strings.TrimSpace(parts[1]),
				util:     strings.TrimSpace(parts[2]),
				memUsed:  strings.TrimSpace(parts[3]),
				memTotal: strings.TrimSpace(parts[4]),
			}

			vramBar := renderVRAMBar(parseMemMiB(g.memUsed), parseMemMiB(g.memTotal))

			info := fmt.Sprintf("temp:%s util:%s", g.temp, g.util)
			rows = append(rows, table.Row{
				"GPU:" + g.name,
				info,
				vramBar,
			})
		}
	}

	out, err = exec.Command("ollama", "list").Output()
	if err == nil {
		lines := strings.Split(strings.TrimSpace(string(out)), "\n")
		for i := 1; i < len(lines); i++ {
			line := strings.TrimSpace(lines[i])
			if line == "" {
				continue
			}
			fields := strings.Fields(line)
			if len(fields) >= 2 {
				name := fields[0]
				size := ""
				if len(fields) >= 3 {
					size = fields[len(fields)-2]
				} else {
					size = fields[len(fields)-1]
				}
				rows = append(rows, table.Row{
					"Ollama:" + name,
					fmt.Sprintf("size:%s", size),
					"",
				})
			}
		}
	}

	out, err = exec.Command("docker", "system", "df", "-v").Output()
	if err == nil {
		scanner := bufio.NewScanner(strings.NewReader(string(out)))
		inOpenCodeSection := false
		for scanner.Scan() {
			line := scanner.Text()
			if strings.Contains(line, "opencode") {
				inOpenCodeSection = true
				fields := strings.Fields(line)
				if len(fields) >= 2 {
					volName := fields[0]
					volSize := fields[1]
					if len(fields) >= 3 {
						volSize = fields[len(fields)-1]
					}
					rows = append(rows, table.Row{
						"Volume:" + volName,
						fmt.Sprintf("disk:%s", volSize),
						"",
					})
				}
				continue
			}
			if inOpenCodeSection && strings.TrimSpace(line) == "" {
				inOpenCodeSection = false
			}
		}
	}

	if len(rows) == 0 {
		rows = append(rows, table.Row{"\u2014", "no GPU / no models", "\u2014"})
	}
	return rows
}

func parseMemMiB(s string) int {
	s = strings.TrimSuffix(strings.TrimSpace(s), " MiB")
	s = strings.TrimSuffix(s, " GiB")
	val, err := strconv.Atoi(s)
	if err != nil {
		return 0
	}
	return val
}

func renderVRAMBar(used, total int) string {
	if total <= 0 {
		return ""
	}
	barWidth := 20
	ratio := float64(used) / float64(total)
	filled := int(ratio * float64(barWidth))
	if filled > barWidth {
		filled = barWidth
	}
	if filled < 0 {
		filled = 0
	}

	barColor := lipgloss.Color("42")
	if ratio > 0.9 {
		barColor = lipgloss.Color("196")
	} else if ratio > 0.7 {
		barColor = lipgloss.Color("220")
	}

	filledBlock := lipgloss.NewStyle().Foreground(barColor).Render(strings.Repeat("\u2588", filled))
	emptyBlock := styleGray.Render(strings.Repeat("\u2591", barWidth-filled))
	pct := fmt.Sprintf(" %.0f%%", ratio*100)

	return fmt.Sprintf("%d/%d MiB %s%s%s", used, total, filledBlock, emptyBlock, pct)
}

type sessionInfo struct {
	path    string
	name    string
	project string
	status  string
	mtime   time.Time
	entries int
}

func fetchSessions() []table.Row {
	var rows []table.Row

	sessionsDir := filepath.Join(configDir, "sessions")
	entries, err := os.ReadDir(sessionsDir)
	if err != nil {
		rows = append(rows, table.Row{"\u2014", "no sessions dir", "\u2014", "\u2014"})
		return rows
	}

	var sessions []sessionInfo
	for _, e := range entries {
		if !e.IsDir() {
			continue
		}
		sessPath := filepath.Join(sessionsDir, e.Name())
		info, err := os.Stat(sessPath)
		if err != nil {
			continue
		}

		si := sessionInfo{
			path:  sessPath,
			name:  e.Name(),
			mtime: info.ModTime(),
		}

		si.project = detectSessionProject(sessPath)
		si.status = detectSessionStatus(sessPath)
		si.entries = countSessionEntries(sessPath)

		sessions = append(sessions, si)
	}

	sort.Slice(sessions, func(i, j int) bool {
		return sessions[i].mtime.After(sessions[j].mtime)
	})

	if len(sessions) > 50 {
		sessions = sessions[:50]
	}

	for _, s := range sessions {
		age := formatAge(s.mtime)
		statusStyled := styleGray.Render("unknown")
		switch s.status {
		case "active":
			statusStyled = styleGreen.Render("active")
		case "idle":
			statusStyled = styleYellow.Render("idle")
		case "completed":
			statusStyled = styleCyan.Render("completed")
		}

		entriesStr := ""
		if s.entries > 0 {
			entriesStr = fmt.Sprintf("%d memories", s.entries)
		}

		rows = append(rows, table.Row{
			s.name,
			s.project,
			statusStyled + " " + age,
			entriesStr,
		})
	}

	if len(rows) == 0 {
		rows = append(rows, table.Row{"\u2014", "no sessions", "\u2014", "\u2014"})
	}
	return rows
}

func detectSessionProject(sessPath string) string {
	statePath := filepath.Join(sessPath, "state.json")
	data, err := os.ReadFile(statePath)
	if err != nil {
		metaPath := filepath.Join(sessPath, "metadata.json")
		data, err = os.ReadFile(metaPath)
		if err != nil {
			return "\u2014"
		}
	}
	var meta struct {
		Project string `json:"project"`
		Title   string `json:"title"`
		CWD     string `json:"cwd"`
	}
	if json.Unmarshal(data, &meta) == nil {
		if meta.Project != "" {
			return meta.Project
		}
		if meta.Title != "" {
			return meta.Title
		}
		if meta.CWD != "" {
			return filepath.Base(meta.CWD)
		}
	}
	return "\u2014"
}

func detectSessionStatus(sessPath string) string {
	statusPath := filepath.Join(sessPath, "status.json")
	data, err := os.ReadFile(statusPath)
	if err != nil {
		statePath := filepath.Join(sessPath, "state.json")
		data, err = os.ReadFile(statePath)
		if err != nil {
			now := time.Now()
			info, err := os.Stat(sessPath)
			if err == nil && now.Sub(info.ModTime()) > 24*time.Hour {
				return "idle"
			}
			return "active"
		}
	}
	var st struct {
		Status string `json:"status"`
		Active bool   `json:"active"`
	}
	if json.Unmarshal(data, &st) == nil {
		if st.Status != "" {
			return st.Status
		}
		if st.Active {
			return "active"
		}
	}
	return "active"
}

func countSessionEntries(sessPath string) int {
	memDir := filepath.Join(sessPath, "memories")
	entries, err := os.ReadDir(memDir)
	if err != nil {
		memFile := filepath.Join(sessPath, "memory.json")
		data, err := os.ReadFile(memFile)
		if err != nil {
			return 0
		}
		var mem struct {
			Entries []interface{} `json:"entries"`
		}
		if json.Unmarshal(data, &mem) == nil {
			return len(mem.Entries)
		}
		return 0
	}
	count := 0
	for _, e := range entries {
		if !e.IsDir() {
			count++
		}
	}
	return count
}

func formatAge(t time.Time) string {
	d := time.Since(t)
	switch {
	case d < time.Minute:
		return "just now"
	case d < time.Hour:
		return fmt.Sprintf("%dm ago", int(d.Minutes()))
	case d < 24*time.Hour:
		return fmt.Sprintf("%dh ago", int(d.Hours()))
	case d < 7*24*time.Hour:
		return fmt.Sprintf("%dd ago", int(d.Hours()/24))
	default:
		return t.Format("Jan 2")
	}
}

func containsStr(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}

func isIsolated() bool {
	configFile := filepath.Join(homeDir, ".config", "opencode-setup", "setup.conf")
	data, err := os.ReadFile(configFile)
	if err != nil {
		return false
	}
	for _, line := range strings.Split(string(data), "\n") {
		line = strings.TrimSpace(line)
		if strings.HasPrefix(line, "ISOLATED_CIRCUIT=") {
			val := strings.TrimPrefix(line, "ISOLATED_CIRCUIT=")
			val = strings.Trim(val, `"'`)
			return val == "true" || val == "1" || val == "yes" || val == "on" || val == "enabled"
		}
	}
	return false
}

func fetchTasks() []table.Row {
	var rows []table.Row

	pluginPath := filepath.Join(configDir, "plugins.json")
	data, err := os.ReadFile(pluginPath)
	hasOrchestrator := false
	if err == nil {
		var reg pluginRegistry
		if json.Unmarshal(data, &reg) == nil {
			for _, name := range reg.Tiers.Always {
				if strings.Contains(name, "orchestrator") {
					hasOrchestrator = true
					break
				}
			}
			if !hasOrchestrator {
				for name, cfg := range reg.Tiers.Conditional {
					if strings.Contains(name, "orchestrator") && cfg.Enabled {
						hasOrchestrator = true
						break
					}
				}
			}
		}
	}

	taskPaths := []string{
		".swarm/plan.json",
		filepath.Join(configDir, "tasks.json"),
		filepath.Join(configDir, "plan.json"),
	}

	var taskFile string
	for _, p := range taskPaths {
		if _, err := os.Stat(p); err == nil {
			taskFile = p
			break
		}
	}

	if taskFile != "" {
		taskData, err := os.ReadFile(taskFile)
		if err == nil {
			var plan struct {
				Phases []struct {
					Name  string `json:"name"`
					Tasks []struct {
						ID          string `json:"id"`
						Description string `json:"description"`
						Status      string `json:"status"`
						Size        string `json:"size"`
					} `json:"tasks"`
				} `json:"phases"`
			}
			if json.Unmarshal(taskData, &plan) == nil {
				for _, phase := range plan.Phases {
					for _, task := range phase.Tasks {
						statusStyled := styleGray.Render(task.Status)
						switch task.Status {
						case "completed", "done":
							statusStyled = styleGreen.Render(task.Status)
						case "in_progress", "in-progress":
							statusStyled = styleYellow.Render(task.Status)
						case "blocked":
							statusStyled = styleRed.Render(task.Status)
						}

						priority := task.Size
						if priority == "" {
							priority = "\u2014"
						}

						agent := "\u2014"
						if hasOrchestrator {
							agent = "orchestrator"
						}

						rows = append(rows, table.Row{
							fmt.Sprintf("%s: %s", task.ID, task.Description),
							statusStyled,
							priority,
							agent,
						})
					}
				}
			}
		}
	}

	if len(rows) == 0 {
		if !hasOrchestrator {
			rows = append(rows, table.Row{"\u2014", "No task tracker configured", "\u2014", "\u2014"})
		} else {
			rows = append(rows, table.Row{"\u2014", "No tasks found", "\u2014", "\u2014"})
		}
	}

	return rows
}

func fetchLogs() []string {
	var lines []string

	serviceUnits := []string{"chromadb", "litellm", "open-webui", "ollama", "cockpit", "searxng", "qdrant"}
	args := []string{"--user", "--no-pager", "-n", "30"}
	for _, u := range serviceUnits {
		args = append(args, "-u", u)
	}

	out, err := exec.Command("journalctl", args...).Output()
	if err != nil {
		lines = append(lines, "journalctl not available or no logs found")
		return lines
	}

	scanner := bufio.NewScanner(strings.NewReader(string(out)))
	for scanner.Scan() {
		line := scanner.Text()
		if strings.TrimSpace(line) != "" {
			lines = append(lines, line)
		}
	}

	if len(lines) == 0 {
		lines = append(lines, "No log entries for opencode services")
	}

	return lines
}

func fetchInfraNames() []string {
	infraFile := filepath.Join(configDir, "infra.yml")
	if _, err := os.Stat(infraFile); os.IsNotExist(err) {
		return nil
	}

	out, err := exec.Command("docker", "compose", "-f", infraFile, "ps", "--format", "{{.Name}}").Output()
	if err != nil {
		return nil
	}

	var names []string
	for _, line := range strings.Split(strings.TrimSpace(string(out)), "\n") {
		if line != "" {
			names = append(names, strings.TrimSpace(line))
		}
	}
	return names
}

func fetchInfra() []table.Row {
	var rows []table.Row

	infraFile := filepath.Join(configDir, "infra.yml")
	if _, err := os.Stat(infraFile); os.IsNotExist(err) {
		rows = append(rows, table.Row{"\u2014", "infra.yml not found", "\u2014"})
		return rows
	}

	out, err := exec.Command("docker", "compose", "-f", infraFile, "ps", "--format", "{{.Name}}\t{{.Status}}\t{{.Ports}}").Output()
	if err != nil {
		rows = append(rows, table.Row{"\u2014", "docker compose unavailable", strconv.Itoa(0)})
		return rows
	}

	for _, line := range strings.Split(strings.TrimSpace(string(out)), "\n") {
		if line == "" {
			continue
		}
		parts := strings.SplitN(line, "\t", 3)
		name := parts[0]
		status := ""
		ports := ""
		if len(parts) >= 2 {
			status = parts[1]
		}
		if len(parts) >= 3 {
			ports = parts[2]
		}

		statusStyled := styleGreen.Render(status)
		lowerS := strings.ToLower(status)
		if strings.Contains(lowerS, "exit") || strings.Contains(lowerS, "down") || strings.Contains(lowerS, "unhealthy") {
			statusStyled = styleRed.Render(status)
		} else if strings.Contains(lowerS, "restarting") {
			statusStyled = styleYellow.Render(status)
		}

		rows = append(rows, table.Row{name, statusStyled, ports})
	}

	if len(rows) == 0 {
		rows = append(rows, table.Row{"\u2014", "no infra services running", "\u2014"})
	}

	return rows
}

func (m *model) fetchWAL() string {
	walPath := filepath.Join(homeDir, ".cache", "opencode-setup", "wal.md")
	data, err := os.ReadFile(walPath)
	if err != nil {
		return "WAL file not found: " + walPath
	}
	return string(data)
}

func (m model) walView() string {
	var sb strings.Builder
	sb.WriteString(styleTitle.Render("  WAL — Write-Ahead Log"))
	sb.WriteString(styleGray.Render("  q/esc:back  ↑↓:scroll\n\n"))

	if m.walContent == "" {
		sb.WriteString(styleGray.Render("  No WAL content available.\n"))
		return sb.String()
	}

	lines := strings.Split(m.walContent, "\n")
	visibleHeight := m.height - 5
	if visibleHeight < 5 {
		visibleHeight = 5
	}

	start := m.walScroll
	end := start + visibleHeight
	if end > len(lines) {
		end = len(lines)
		start = end - visibleHeight
		if start < 0 {
			start = 0
		}
	}

	for i := start; i < end; i++ {
		prefix := "  "
		if i == m.walScroll {
			prefix = styleCyan.Render("> ")
		}
		sb.WriteString(prefix + colorizeLogLine(lines[i]) + "\n")
	}

	scrollPct := 0
	if len(lines) > 1 {
		scrollPct = (m.walScroll * 100) / (len(lines) - 1)
	}
	sb.WriteString(styleGray.Render(fmt.Sprintf("\n  ── %d%% scrolled  q/esc:back ──\n", scrollPct)))

	return sb.String()
}

func (m model) pluginsView() string {
	if len(m.pluginRows) == 0 {
		return m.tables[1].View()
	}

	rows := make([]table.Row, len(m.pluginRows))
	for i, pr := range m.pluginRows {
		statusStr := styleGray.Render("disabled")
		if pr.enabled {
			statusStr = styleGreen.Render("enabled")
		}
		prefix := ""
		if i == m.pluginSel {
			prefix = styleCyan.Render("\u25b6 ")
		}
		rows[i] = table.Row{prefix + pr.name, pr.tier, statusStr}
	}

	m.tables[1].SetRows(rows)
	return m.tables[1].View()
}

func (m *model) togglePlugin(name string, enable bool) {
	pluginPath := filepath.Join(configDir, "plugins.json")
	data, err := os.ReadFile(pluginPath)
	if err != nil {
		return
	}

	var reg pluginRegistry
	if err := json.Unmarshal(data, &reg); err != nil {
		return
	}

	for i, n := range reg.Tiers.Always {
		if n == name {
			if enable {
				_ = i
			}
			break
		}
	}

	if cfg, ok := reg.Tiers.Conditional[name]; ok {
		cfg.Enabled = enable
		if enable {
			cfg.AutoEnable = false
		}
		reg.Tiers.Conditional[name] = cfg
		updated, _ := json.MarshalIndent(reg, "", "  ")
		os.WriteFile(pluginPath, updated, 0644)
		return
	}

	for i, n := range reg.Tiers.OnDemand {
		if n == name {
			if !enable {
				reg.Tiers.OnDemand = append(reg.Tiers.OnDemand[:i], reg.Tiers.OnDemand[i+1:]...)
			}
			updated, _ := json.MarshalIndent(reg, "", "  ")
			os.WriteFile(pluginPath, updated, 0644)
			return
		}
	}

	updated, _ := json.MarshalIndent(reg, "", "  ")
	os.WriteFile(pluginPath, updated, 0644)
}

func newTable(cols []table.Column) table.Model {
	t := table.New(
		table.WithColumns(cols),
		table.WithFocused(false),
		table.WithHeight(20),
	)
	s := table.DefaultStyles()
	s.Header = s.Header.
		BorderStyle(lipgloss.NormalBorder()).
		BorderForeground(lipgloss.Color("240")).
		BorderBottom(true).
		Bold(true)
	s.Selected = s.Selected.Foreground(lipgloss.Color("99"))
	t.SetStyles(s)
	return t
}

func main() {
	tabs := []string{"Services", "Plugins", "GPU", "Sessions", "Tasks", "Logs", "Infra"}

	svcCols := []table.Column{
		{Title: "Name", Width: 35},
		{Title: "Status", Width: 30},
		{Title: "Extra", Width: 40},
	}
	plugCols := []table.Column{
		{Title: "Plugin", Width: 30},
		{Title: "Tier", Width: 15},
		{Title: "Status", Width: 22},
		{Title: "Dependencies", Width: 40},
	}
	gpuCols := []table.Column{
		{Title: "GPU / Model", Width: 40},
		{Title: "Info", Width: 20},
		{Title: "Memory", Width: 50},
	}
	sessCols := []table.Column{
		{Title: "Session", Width: 30},
		{Title: "Project", Width: 25},
		{Title: "Status", Width: 25},
		{Title: "Memory", Width: 20},
	}
	taskCols := []table.Column{
		{Title: "Task", Width: 50},
		{Title: "Status", Width: 20},
		{Title: "Priority", Width: 15},
		{Title: "Agent", Width: 20},
	}
	logsCols := []table.Column{
		{Title: "Logs", Width: 110},
	}
	infraCols := []table.Column{
		{Title: "Service", Width: 40},
		{Title: "Status", Width: 35},
		{Title: "Ports", Width: 35},
	}

	tables := []table.Model{
		newTable(svcCols),
		newTable(plugCols),
		newTable(gpuCols),
		newTable(sessCols),
		newTable(taskCols),
		newTable(logsCols),
		newTable(infraCols),
	}

	m := model{
		tabs:      tabs,
		activeTab: 0,
		tables:    tables,
	}

	p := tea.NewProgram(m, tea.WithAltScreen())
	if _, err := p.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "cockpit error: %v\n", err)
		os.Exit(1)
	}
}

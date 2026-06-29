package main

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/bubbles/table"
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
}

func (m model) Init() tea.Cmd {
	return tea.Batch(tick(), tea.Tick(refreshInterval, func(t time.Time) tea.Msg { return refreshTick{} }))
}

type refreshTick struct{}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmds []tea.Cmd

	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "q", "ctrl+c", "esc":
			return m, tea.Quit
		case "r":
			m.loading = true
			return m, tick()
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
		m.loading = false

	case refreshTick:
		cmds = append(cmds, tick())
	}

	activeIdx := m.activeTab
	var cmd tea.Cmd
	m.tables[activeIdx], cmd = m.tables[activeIdx].Update(msg)
	if cmd != nil {
		cmds = append(cmds, cmd)
	}

	return m, tea.Batch(cmds...)
}

func (m model) View() string {
	title := styleTitle.Render("opencode-cockpit v1.0.0")
	status := ""
	if m.loading {
		status = styleLoading.Render(" ⟳ refreshing...")
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

	activeTable := m.tables[m.activeTab].View()

	help := "\n 1:Srv 2:Plugins 3:GPU 4:Sessions  Tab/Shift+Tab  r:refresh  q:quit\n"

	return header + tabBar + activeTable + help
}

type tickResult struct {
	services []table.Row
	plugins  []table.Row
	gpu      []table.Row
	sessions []table.Row
}

func tick() tea.Cmd {
	return func() tea.Msg {
		return tickResult{
			services: fetchServices(),
			plugins:  fetchPlugins(),
			gpu:      fetchGPU(),
			sessions: fetchSessions(),
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
		rows = append(rows, table.Row{"—", "no services detected", "—"})
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

func fetchPlugins() []table.Row {
	var rows []table.Row

	pluginPath := filepath.Join(configDir, "plugins.json")
	data, err := os.ReadFile(pluginPath)
	if err != nil {
		rows = append(rows, table.Row{"—", "no plugins.json", "—", "—"})
		return rows
	}

	var reg pluginRegistry
	if err := json.Unmarshal(data, &reg); err != nil {
		rows = append(rows, table.Row{"—", "invalid json", "—", "—"})
		return rows
	}

	for _, name := range reg.Tiers.Always {
		installed := pluginInstalled(name)
		if installed {
			rows = append(rows, table.Row{name, styleGreen.Render("always"), styleGreen.Render("enabled"), "—"})
		} else {
			rows = append(rows, table.Row{name, styleGray.Render("always"), styleGray.Render("not installed"), "—"})
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
		var statusStr string
		if ce.cfg.Enabled && depsMet {
			statusStr = styleGreen.Render("enabled")
		} else if ce.cfg.Enabled && !depsMet {
			statusStr = styleYellow.Render("awaiting deps")
		} else if ce.cfg.AutoEnable && depsMet {
			statusStr = styleGreen.Render("auto-enabled")
		} else if ce.cfg.AutoEnable && !depsMet {
			statusStr = styleYellow.Render("awaiting deps (auto)")
		} else {
			statusStr = styleGray.Render("disabled")
		}

		depsInfo := ""
		if len(ce.cfg.Depends) > 0 {
			var parts []string
			for _, d := range ce.cfg.Depends {
				if containsStr(depsMet, d) {
					parts = append(parts, styleGreen.Render("✓"+d))
				} else {
					parts = append(parts, styleRed.Render("✗"+d))
				}
			}
			for _, d := range depsMissing {
				parts = append(parts, styleRed.Render("✗"+d))
			}
			depsInfo = strings.Join(parts, " ")
		}
		rows = append(rows, table.Row{ce.name, tier, statusStr, depsInfo})
	}

	for _, name := range reg.Tiers.OnDemand {
		installed := pluginInstalled(name)
		if installed {
			rows = append(rows, table.Row{name, styleMagenta.Render("on-demand"), styleGreen.Render("available"), "—"})
		} else {
			rows = append(rows, table.Row{name, styleMagenta.Render("on-demand"), styleGray.Render("not installed"), "—"})
		}
	}

	if len(rows) == 0 {
		rows = append(rows, table.Row{"—", "no plugins registered", "—", "—"})
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

	if len(rows) == 0 {
		rows = append(rows, table.Row{"—", "no GPU / no models", "—"})
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

	filledBlock := lipgloss.NewStyle().Foreground(barColor).Render(strings.Repeat("█", filled))
	emptyBlock := styleGray.Render(strings.Repeat("░", barWidth-filled))
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
		rows = append(rows, table.Row{"—", "no sessions dir", "—", "—"})
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
		rows = append(rows, table.Row{"—", "no sessions", "—", "—"})
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
			return "—"
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
	return "—"
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
	tabs := []string{"Services", "Plugins", "GPU", "Sessions"}

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

	tables := []table.Model{
		newTable(svcCols),
		newTable(plugCols),
		newTable(gpuCols),
		newTable(sessCols),
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

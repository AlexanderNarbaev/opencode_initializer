package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/bubbles/table"
	"github.com/charmbracelet/lipgloss"
)

type model struct {
	table   table.Model
	width   int
	height  int
	loading bool
}

func (m model) Init() tea.Cmd { return tick }

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "q", "ctrl+c", "esc":
			return m, tea.Quit
		case "r":
			m.loading = true
			return m, tick
		}
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		m.table.SetWidth(msg.Width - 4)
		m.table.SetHeight(msg.Height - 8)
	case statusMsg:
		m.table.SetRows(msg.rows)
		m.loading = false
		return m, tick
	}

	var cmd tea.Cmd
	m.table, cmd = m.table.Update(msg)
	return m, cmd
}

func (m model) View() string {
	title := lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("99")).Render("opencode-cockpit v0.1.0")
	status := ""
	if m.loading {
		status = lipgloss.NewStyle().Foreground(lipgloss.Color("240")).Render(" ⟳ refreshing...")
	}
	header := fmt.Sprintf("%s%s\n\n", title, status)
	help := "\n F1:Srv F2:Plugins F3:GPU F5:Tasks q:quit r:refresh\n"
	return header + m.table.View() + help
}

type statusMsg struct {
	rows []table.Row
}

func tick() tea.Msg {
	rows := []table.Row{}

	// Docker containers
	out, err := exec.Command("docker", "ps", "--format", "{{.Names}}\t{{.Status}}\t{{.Ports}}").Output()
	if err == nil {
		for _, line := range strings.Split(strings.TrimSpace(string(out)), "\n") {
			parts := strings.SplitN(line, "\t", 3)
			if len(parts) >= 2 {
				rows = append(rows, table.Row{parts[0], parts[1], safeGet(parts, 2)})
			}
		}
	}

	// Systemd user services
	out, err = exec.Command("systemctl", "--user", "list-units", "--type=service", "--no-legend").Output()
	if err == nil {
		for _, line := range strings.Split(strings.TrimSpace(string(out)), "\n") {
			fields := strings.Fields(line)
			if len(fields) >= 4 && strings.Contains(line, "opencode") || strings.Contains(line, "chroma") || strings.Contains(line, "litellm") || strings.Contains(line, "webui") || strings.Contains(line, "ollama") {
				rows = append(rows, table.Row{"systemd:" + fields[0], fields[3], ""})
			}
		}
	}

	return statusMsg{rows: rows}
}

func safeGet(parts []string, i int) string {
	if i < len(parts) {
		return parts[i]
	}
	return ""
}

func main() {
	columns := []table.Column{
		{Title: "Name", Width: 30},
		{Title: "Status", Width: 30},
		{Title: "Extra", Width: 40},
	}

	t := table.New(
		table.WithColumns(columns),
		table.WithFocused(false),
		table.WithHeight(20),
	)
	s := table.DefaultStyles()
	s.Header = s.Header.BorderStyle(lipgloss.NormalBorder()).BorderForeground(lipgloss.Color("240")).BorderBottom(true).Bold(true)
	s.Selected = s.Selected.Foreground(lipgloss.Color("99"))
	t.SetStyles(s)

	m := model{table: t}
	p := tea.NewProgram(m, tea.WithAltScreen())
	if _, err := p.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "cockpit error: %v\n", err)
		os.Exit(1)
	}
}

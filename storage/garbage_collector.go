package storage

import (
	"fmt"
	"os"
	"path/filepath"
)

var bblManaged = map[string]struct{}{
	"bbl.tfvars":               struct{}{},
	"bosh-state.json":          struct{}{},
	"cloud-config-vars.yml":    struct{}{},
	"director-vars-file.yml":   struct{}{},
	"director-vars-store.yml":  struct{}{},
	"jumpbox-state.json":       struct{}{},
	"jumpbox-vars-file.yml":    struct{}{},
	"jumpbox-vars-store.yml":   struct{}{},
	"terraform.tfstate":        struct{}{},
	"terraform.tfstate.backup": struct{}{},
}

type printer interface {
	Printf(message string, a ...interface{})
}

type GarbageCollector struct {
	fs fs
	printer printer
}

func NewGarbageCollector(fs fs, printer printer) GarbageCollector {
	return GarbageCollector{
		fs: fs,
		printer: printer,
	}
}

func (g GarbageCollector) warnForUserManagedFiles(dir string) {
	files, _ := g.fs.ReadDir(dir)
	for _, f := range files {
		filePath := filepath.Join(dir, f.Name())
		g.printer.Printf(filePath)
	}
}

func (g GarbageCollector) Remove(dir string) error {
	bblStateJson := filepath.Join(dir, STATE_FILE)
	err := g.fs.Remove(bblStateJson)
	if err != nil && !os.IsNotExist(err) {
		return fmt.Errorf("Removing %s: %s", bblStateJson, err)
	}

	g.fs.RemoveAll(filepath.Join(dir, "bosh-deployment"))
	g.fs.RemoveAll(filepath.Join(dir, "jumpbox-deployment"))
	g.fs.RemoveAll(filepath.Join(dir, "bbl-ops-files"))

	tfDir := filepath.Join(dir, "terraform")
	g.fs.Remove(filepath.Join(tfDir, "bbl-template.tf"))
	g.fs.RemoveAll(filepath.Join(tfDir, ".terraform")) // if we delete this every time to prompt, we're gonna waste internets
	g.fs.Remove(tfDir)
	
	g.warnForUserManagedFiles(tfDir)

	ccDir := filepath.Join(dir, "cloud-config")
	g.fs.Remove(filepath.Join(ccDir, "cloud-config.yml"))
	g.fs.Remove(filepath.Join(ccDir, "ops.yml"))
	g.fs.Remove(ccDir)
	g.warnForUserManagedFiles(ccDir)


	vDir := filepath.Join(dir, "vars")
	vFiles, _ := g.fs.ReadDir(vDir)
	for _, f := range vFiles {
		filePath := filepath.Join(vDir, f.Name())
		if _, ok := bblManaged[f.Name()]; ok {
			_ = g.fs.Remove(filePath)
		}
	}
	g.fs.Remove(vDir)
	g.warnForUserManagedFiles(vDir)

	g.fs.RemoveAll(filepath.Join(dir, ".terraform"))
	g.fs.Remove(filepath.Join(dir, "create-jumpbox.sh"))
	g.fs.Remove(filepath.Join(dir, "create-director.sh"))
	g.fs.Remove(filepath.Join(dir, "delete-jumpbox.sh"))
	g.fs.Remove(filepath.Join(dir, "delete-director.sh"))

	return nil
}

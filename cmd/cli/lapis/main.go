package main

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"time"
)

func main() {
	b, err := exec.Command("iwctl", "station", "wlan0", "scan").CombinedOutput()
	if err != nil {
		fmt.Println("scan", string(b))
		os.Exit(1)
	}
	for range 10 {
		b, err = exec.Command("iwctl", "station", "wlan0", "get-networks").CombinedOutput()
		if err != nil {
			fmt.Println("get-networks:", string(b))
			time.Sleep(time.Second)
			continue
		}
		if !bytes.Contains(b, []byte("lapis")) {
			fmt.Println("lapis not in networks, sleeping...")
			time.Sleep(time.Second)
			continue
		}
		break
	}
	b, err = exec.Command("iwctl", "station", "wlan0", "connect", "lapis").CombinedOutput()
	if err != nil {
		fmt.Println("connect", string(b))
		os.Exit(1)
	}
}

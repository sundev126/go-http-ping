package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"
)

const shutdownTimeout = 5 * time.Second

func main() {
	if err := run(); err != nil {
		log.Printf("go-http-ping: %v", err)
		os.Exit(1)
	}
}

func run() error {
	ip := flag.String("ip", "0.0.0.0", "监听 IP 地址")
	port := flag.Int("port", 8080, "监听端口")
	response := flag.String("response", "ok", "访问 /ping 时返回的内容")
	flag.Parse()

	if *port < 1 || *port > 65535 {
		return fmt.Errorf("端口必须在 1 到 65535 之间: %d", *port)
	}

	server := &http.Server{
		Addr:              net.JoinHostPort(*ip, strconv.Itoa(*port)),
		Handler:           newHandler(*response),
		ReadHeaderTimeout: 5 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt, syscall.SIGTERM)
	defer signal.Stop(stop)

	errCh := make(chan error, 1)
	go func() {
		log.Printf("listening on http://%s", server.Addr)
		errCh <- server.ListenAndServe()
	}()

	select {
	case err := <-errCh:
		if errors.Is(err, http.ErrServerClosed) {
			return nil
		}
		return err
	case sig := <-stop:
		log.Printf("received %s, shutting down", sig)
	}

	ctx, cancel := context.WithTimeout(context.Background(), shutdownTimeout)
	defer cancel()
	return server.Shutdown(ctx)
}

func newHandler(response string) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("/ping", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/plain; charset=utf-8")
		_, _ = w.Write([]byte(response))
	})
	return mux
}

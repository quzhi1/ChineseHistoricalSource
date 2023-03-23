package util

import (
	"context"
	"os"

	"github.com/rs/zerolog"
)

func GetLoggerCtx() context.Context {
	logger := zerolog.New(os.Stdout).With().Timestamp().Logger()
	logger = logger.With().CallerWithSkipFrameCount(zerolog.CallerSkipFrameCount).Logger()
	zerolog.LevelFieldName = "severity"
	logger = logger.Output(zerolog.ConsoleWriter{Out: os.Stderr})
	return logger.WithContext(context.Background())
}

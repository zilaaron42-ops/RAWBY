FROM dart:stable AS build
WORKDIR /app
COPY server/ .
RUN dart pub get

FROM dart:stable
WORKDIR /app
COPY --from=build /app .
EXPOSE 8080
CMD ["dart", "run", "bin/server.dart"]

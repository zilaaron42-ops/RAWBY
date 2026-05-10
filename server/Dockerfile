FROM dart:stable AS build
WORKDIR /app
COPY server/ .
RUN dart --version && dart pub get && dart compile exe bin/server.dart -o bin/server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server
EXPOSE 8080
CMD ["/app/bin/server"]

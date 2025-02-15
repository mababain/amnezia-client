#include "awg_configurator.h"

#include <QJsonDocument>
#include <QJsonObject>

#include "core/controllers/serverController.h"

AwgConfigurator::AwgConfigurator(std::shared_ptr<Settings> settings, QObject *parent)
    : WireguardConfigurator(settings, true, parent)
{
}

QString AwgConfigurator::createConfig(const ServerCredentials &credentials, DockerContainer container,
                                      const QJsonObject &containerConfig, ErrorCode errorCode)
{
    QString config = WireguardConfigurator::createConfig(credentials, container, containerConfig, errorCode);

    QJsonObject jsonConfig = QJsonDocument::fromJson(config.toUtf8()).object();
    QString awgConfig = jsonConfig.value(config_key::config).toString();

    QMap<QString, QString> configMap;
    auto configLines = awgConfig.split("\n");
    for (auto &line : configLines) {
        auto trimmedLine = line.trimmed();
        if (trimmedLine.startsWith("[") && trimmedLine.endsWith("]")) {
            continue;
        } else {
            QStringList parts = trimmedLine.split(" = ");
            if (parts.count() == 2) {
                configMap.insert(parts[0].trimmed(), parts[1].trimmed());
            }
        }
    }

    jsonConfig[config_key::junkPacketCount] = configMap.value(config_key::junkPacketCount);
    jsonConfig[config_key::junkPacketMinSize] = configMap.value(config_key::junkPacketMinSize);
    jsonConfig[config_key::junkPacketMaxSize] = configMap.value(config_key::junkPacketMaxSize);
    jsonConfig[config_key::initPacketJunkSize] = configMap.value(config_key::initPacketJunkSize);
    jsonConfig[config_key::responsePacketJunkSize] = configMap.value(config_key::responsePacketJunkSize);
    jsonConfig[config_key::initPacketMagicHeader] = configMap.value(config_key::initPacketMagicHeader);
    jsonConfig[config_key::responsePacketMagicHeader] = configMap.value(config_key::responsePacketMagicHeader);
    jsonConfig[config_key::underloadPacketMagicHeader] = configMap.value(config_key::underloadPacketMagicHeader);
    jsonConfig[config_key::transportPacketMagicHeader] = configMap.value(config_key::transportPacketMagicHeader);
    jsonConfig[config_key::mtu] = containerConfig.value(ProtocolProps::protoToString(Proto::Awg)).toObject().
                                  value(config_key::mtu).toString(protocols::awg::defaultMtu);

    return QJsonDocument(jsonConfig).toJson();
}

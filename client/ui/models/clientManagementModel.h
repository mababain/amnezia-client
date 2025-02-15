#ifndef CLIENTMANAGEMENTMODEL_H
#define CLIENTMANAGEMENTMODEL_H

#include <QAbstractListModel>
#include <QJsonArray>

#include "core/controllers/serverController.h"
#include "settings.h"

class ClientManagementModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Roles {
        ClientNameRole = Qt::UserRole + 1,
        CreationDateRole
    };

    ClientManagementModel(std::shared_ptr<Settings> settings, QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;

public slots:
    ErrorCode updateModel(DockerContainer container, ServerCredentials credentials);
    ErrorCode appendClient(const DockerContainer container, const ServerCredentials &credentials, const QJsonObject &containerConfig,
                           const QString &clientName);
    ErrorCode appendClient(const QString &clientId, const QString &clientName, const DockerContainer container,
                           ServerCredentials credentials);
    ErrorCode renameClient(const int row, const QString &userName, const DockerContainer container, ServerCredentials credentials,
                           bool addTimeStamp = false);
    ErrorCode revokeClient(const int index, const DockerContainer container, ServerCredentials credentials, const int serverIndex);
    ErrorCode revokeClient(const QJsonObject &containerConfig, const DockerContainer container, ServerCredentials credentials, const int serverIndex);

protected:
    QHash<int, QByteArray> roleNames() const override;

signals:
    void adminConfigRevoked(const DockerContainer container);

private:
    bool isClientExists(const QString &clientId);

    void migration(const QByteArray &clientsTableString);

    ErrorCode revokeOpenVpn(const int row, const DockerContainer container, ServerCredentials credentials, const int serverIndex);
    ErrorCode revokeWireGuard(const int row, const DockerContainer container, ServerCredentials credentials);

    ErrorCode getOpenVpnClients(ServerController &serverController, DockerContainer container, ServerCredentials credentials, int &count);
    ErrorCode getWireGuardClients(ServerController &serverController, DockerContainer container, ServerCredentials credentials, int &count);

    QJsonArray m_clientsTable;

    std::shared_ptr<Settings> m_settings;
};

#endif // CLIENTMANAGEMENTMODEL_H

/// Tipo de ação da tela de ocorrência. Fica isolado do controller para que
/// widgets puros (e os previews) possam usá-lo sem puxar GetX/sqflite.
enum ActionType { signature, observation, finish }
